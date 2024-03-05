import {groupBy, Logger, mapValues, mergeBy, removeUndefined, sequence, mapValuesAsync} from "@azimutt/utils";
import {
    AzimuttRelation,
    AzimuttSchema,
    AzimuttType,
    isPolymorphicColumn,
    schemaToColumns,
    ValueSchema,
    valuesToSchema
} from "@azimutt/database-types";
import {Conn} from "./common";

export type MysqlSchema = { tables: MysqlTable[], relations: AzimuttRelation[], types: AzimuttType[] }
export type MysqlTable = { schema: MysqlSchemaName, table: MysqlTableName, view: boolean, columns: MysqlColumn[], primaryKey: MysqlPrimaryKey | null, uniques: MysqlUnique[], indexes: MysqlIndex[], checks: MysqlCheck[], comment: string | null }
export type MysqlColumn = { name: MysqlColumnName, type: MysqlColumnType, nullable: boolean, default: string | null, comment: string | null, schema: ValueSchema | null }
export type MysqlPrimaryKey = { name: string | null, columns: MysqlColumnName[] }
export type MysqlUnique = { name: string, columns: MysqlColumnName[], definition: string | null }
export type MysqlIndex = { name: string, columns: MysqlColumnName[], definition: string | null }
export type MysqlCheck = { name: string, columns: MysqlColumnName[], predicate: string | null }
export type MysqlColumnRef = { schema: MysqlSchemaName, table: MysqlTableName, column: MysqlColumnName }
export type MysqlSchemaName = string
export type MysqlTableName = string
export type MysqlColumnName = string
export type MysqlColumnType = string
export type MysqlConstraintName = string
export type MysqlTableId = string

export type MysqlSchemaOpts = {logger: Logger, schema: MysqlSchemaName | undefined, sampleSize: number, inferRelations: boolean, ignoreErrors: boolean}
export const getSchema = ({logger, schema, sampleSize, inferRelations, ignoreErrors}: MysqlSchemaOpts) => async (conn: Conn): Promise<MysqlSchema> => {
    const columns = await getColumns(conn, schema, ignoreErrors, logger)
        .then(cols => groupBy(cols, toTableId))
        .then(cols => mapValuesAsync(cols, tableCols => enrichColumnsWithSchema(conn, tableCols, sampleSize, inferRelations, ignoreErrors, logger)))
    const comments = await getTableComments(conn, schema, ignoreErrors, logger).then(tables => groupBy(tables, toTableId))
    const constraints = await getAllConstraints(conn, schema, ignoreErrors, logger).then(constraints => mapValues(groupBy(constraints, toTableId), buildTableConstraints))
    return {
        tables: Object.entries(columns).map(([tableId, columns]) => {
            const tableConstraints = constraints[tableId] || []
            const tableComments = comments[tableId] || []
            return {
                schema: columns[0].schema,
                table: columns[0].table,
                view: columns[0].table_kind === 'VIEW',
                columns: columns
                    .sort((a, b) => a.column_index - b.column_index)
                    .map(col => ({
                        name: col.column,
                        type: col.column_type,
                        nullable: col.column_nullable === 'YES',
                        default: col.column_default,
                        comment: col.column_comment || null,
                        schema: col.column_schema || null
                    })),
                primaryKey: tableConstraints.filter((c): c is ConstraintPrimaryKey => c.type === 'PRIMARY KEY').map(c => ({
                    name: c.constraint,
                    columns: c.columns
                }))[0] || null,
                uniques: tableConstraints.filter((c): c is ConstraintUnique => c.type === 'UNIQUE').map(c => ({
                    name: c.constraint,
                    columns: c.columns,
                    definition: null
                })) || [],
                indexes: tableConstraints.filter((c): c is ConstraintIndex => c.type === 'INDEX').map(c => ({
                    name: c.constraint,
                    columns: c.columns,
                    definition: null
                })) || [],
                checks: /* TODO tableConstraints.filter(c => c.constraint_type === 'c').map(c => ({
                name: c.constraint_name,
                columns: c.columns.map(getColumnName(tableId)),
                predicate: c.definition.replace(/^CHECK/, '').trim()
            })) || */ [],
                comment: tableComments[0]?.comment || null
            }
        }),
        relations: Object.values(constraints).flat().filter((c): c is ConstraintForeignKey => c.type === 'FOREIGN KEY').flatMap(c => c.columns.map(col => ({
            name: c.constraint,
            src: {schema: c.schema, table: c.table, column: col.src},
            ref: {schema: col.ref.schema, table: col.ref.table, column: col.ref.column}
        }))),
        types: [] // TODO
    }
}

export function formatSchema(schema: MysqlSchema): AzimuttSchema {
    return {
        tables: schema.tables.map(t => removeUndefined({
            schema: t.schema,
            table: t.table,
            columns: t.columns.map(c => removeUndefined({
                name: c.name,
                type: c.type,
                nullable: c.nullable || undefined,
                default: c.default || undefined,
                comment: c.comment || undefined,
                columns: c.schema ? schemaToColumns(c.schema, 0) : undefined
            })),
            view: t.view || undefined,
            primaryKey: t.primaryKey ? removeUndefined({
                name: t.primaryKey.name || undefined,
                columns: t.primaryKey.columns,
            }) : undefined,
            uniques: t.uniques.length > 0 ? t.uniques.map(u => removeUndefined({
                name: u.name || undefined,
                columns: u.columns,
                definition: u.definition || undefined
            })) : undefined,
            indexes: t.indexes.length > 0 ? t.indexes.map(i => removeUndefined({
                name: i.name || undefined,
                columns: i.columns,
                definition: i.definition || undefined
            })) : undefined,
            checks: t.checks.length > 0 ? t.checks.map(c => removeUndefined({
                name: c.name || undefined,
                columns: c.columns,
                predicate: c.predicate || undefined
            })) : undefined,
            comment: t.comment || undefined
        })),
        relations: schema.relations,
        types: schema.types
    }
}

// 👇️ Private functions, some are exported only for tests
// If you use them, beware of breaking changes!

function toTableId<T extends { schema: string, table: string }>(value: T): MysqlTableId {
    return `${value.schema}.${value.table}`
}

type RawColumn = {
    schema: MysqlSchemaName
    table: MysqlTableName
    table_kind: 'BASE TABLE' | 'VIEW'
    column: MysqlColumnName
    column_type: MysqlColumnType
    column_index: number
    column_default: string | null
    column_nullable: 'YES' | 'NO'
    column_comment: string
    column_schema?: ValueSchema
}

async function getColumns(conn: Conn, schema: MysqlSchemaName | undefined, ignoreErrors: boolean, logger: Logger): Promise<RawColumn[]> {
    return conn.query<RawColumn>(
        `SELECT c.TABLE_SCHEMA     AS "schema",
                c.TABLE_NAME       AS "table",
                t.TABLE_TYPE       AS table_kind,
                c.COLUMN_NAME      AS "column",
                c.COLUMN_TYPE      AS column_type,
                c.ORDINAL_POSITION AS column_index,
                c.COLUMN_DEFAULT   AS column_default,
                c.IS_NULLABLE      AS column_nullable,
                c.COLUMN_COMMENT   AS column_comment
         FROM information_schema.COLUMNS c
                  JOIN information_schema.TABLES t ON c.TABLE_SCHEMA = t.TABLE_SCHEMA AND c.TABLE_NAME = t.TABLE_NAME
         WHERE ${filterSchema('c.TABLE_SCHEMA', schema)}
         ORDER BY "schema", "table", column_index;`, [], 'getColumns'
    ).catch(handleError(`Failed to get columns${schema ? ` for schema '${schema}'` : ''}`, [], ignoreErrors, logger))
}

function enrichColumnsWithSchema(conn: Conn, tableCols: RawColumn[], sampleSize: number, inferRelations: boolean, ignoreErrors: boolean, logger: Logger): Promise<RawColumn[]> {
    const colNames = tableCols.map(c => c.column)
    return sequence(tableCols, async c => {
        if (sampleSize > 0 && c.column_type === 'jsonb') {
            return getColumnSchema(conn, c.schema, c.table, c.column, sampleSize, ignoreErrors, logger).then(column_schema => ({...c, column_schema}))
        } else if (inferRelations && isPolymorphicColumn(c.column, colNames)) {
            return c // TODO: fetch distinct values
        } else {
            return c
        }
    })
}

async function getColumnSchema(conn: Conn, schema: string, table: string, column: string, sampleSize: number, ignoreErrors: boolean, logger: Logger): Promise<ValueSchema> {
    const sqlTable = `${schema ? `${schema}.` : ''}${table}`
    return conn.query(`SELECT ${column} FROM ${sqlTable} WHERE ${column} IS NOT NULL LIMIT ${sampleSize};`, [], 'getColumnSchema')
        .then(rows => valuesToSchema(rows.map(row => row[column])))
        .catch(handleError(`Failed to infer schema for column '${column}' of table '${schema ? schema + '.' : ''}${table}'`, valuesToSchema([]), ignoreErrors, logger))
}

type RawTable = {
    schema: MysqlSchemaName
    table: MysqlTableName
    comment: string
}

function getTableComments(conn: Conn, schema: MysqlSchemaName | undefined, ignoreErrors: boolean, logger: Logger): Promise<RawTable[]> {
    return conn.query<RawTable>(
        `SELECT TABLE_SCHEMA  AS "schema",
                TABLE_NAME    AS "table",
                TABLE_COMMENT AS comment
         FROM information_schema.TABLES
         WHERE TABLE_COMMENT != ''
           AND TABLE_COMMENT != 'VIEW'
           AND ${filterSchema('TABLE_SCHEMA', schema)};`, [], 'getTableComments'
    ).catch(handleError(`Failed to get table comments${schema ? ` for schema '${schema}'` : ''}`, [], ignoreErrors, logger))
}

type RawConstraint = {
    schema: MysqlSchemaName
    table: MysqlTableName
    constraint: MysqlConstraintName
    column: MysqlColumnName
    type: 'PRIMARY KEY' | 'UNIQUE' | 'FOREIGN KEY' | 'INDEX'
    index?: number
    ref_schema?: MysqlSchemaName
    ref_table?: MysqlTableName
    ref_column?: MysqlColumnName
}

async function getAllConstraints(conn: Conn, schema: MysqlSchemaName | undefined, ignoreErrors: boolean, logger: Logger): Promise<RawConstraint[]> {
    const [indexes, constraints] = await Promise.all([getIndexes(conn, schema, ignoreErrors, logger), getConstraints(conn, schema, ignoreErrors, logger)])
    return mergeBy(indexes, constraints, c => `${c.schema}.${c.table}.${c.constraint}.${c.column}`)
}

function getIndexes(conn: Conn, schema: MysqlSchemaName | undefined, ignoreErrors: boolean, logger: Logger): Promise<RawConstraint[]> {
    return conn.query<RawConstraint>(
        `SELECT INDEX_SCHEMA AS "schema",
                TABLE_NAME   AS "table",
                INDEX_NAME   AS "constraint",
                COLUMN_NAME  AS "column",
                SEQ_IN_INDEX AS "index",
                "INDEX"      AS type
         FROM information_schema.STATISTICS
         WHERE ${filterSchema('INDEX_SCHEMA', schema)};`, [], 'getIndexes'
    ).catch(handleError(`Failed to get indexes${schema ? ` for schema '${schema}'` : ''}`, [], ignoreErrors, logger))
}

function getConstraints(conn: Conn, schema: MysqlSchemaName | undefined, ignoreErrors: boolean, logger: Logger): Promise<RawConstraint[]> {
    return conn.query<RawConstraint>(
        `SELECT c.CONSTRAINT_SCHEMA       AS "schema",
                c.TABLE_NAME              AS "table",
                c.CONSTRAINT_NAME         AS "constraint",
                u.COLUMN_NAME             AS "column",
                c.CONSTRAINT_TYPE         AS type,
                u.REFERENCED_TABLE_SCHEMA AS ref_schema,
                u.REFERENCED_TABLE_NAME   AS ref_table,
                u.REFERENCED_COLUMN_NAME  AS ref_column
         FROM information_schema.TABLE_CONSTRAINTS c
                  JOIN information_schema.KEY_COLUMN_USAGE u
                       ON c.CONSTRAINT_SCHEMA = u.CONSTRAINT_SCHEMA AND c.TABLE_NAME = u.TABLE_NAME AND
                          c.CONSTRAINT_NAME = u.CONSTRAINT_NAME
         WHERE ${filterSchema('c.CONSTRAINT_SCHEMA', schema)};`, [], 'getConstraints'
    ).catch(handleError(`Failed to get constraints${schema ? ` for schema '${schema}'` : ''}`, [], ignoreErrors, logger))
}

type ConstraintBase = { schema: MysqlSchemaName, table: MysqlTableName, constraint: MysqlConstraintName }
type ConstraintPrimaryKey = ConstraintBase & { type: 'PRIMARY KEY', columns: MysqlColumnName[] }
type ConstraintUnique = ConstraintBase & { type: 'UNIQUE', columns: MysqlColumnName[] }
type ConstraintIndex = ConstraintBase & { type: 'INDEX', columns: MysqlColumnName[] }
type ConstraintForeignKey = ConstraintBase & { type: 'FOREIGN KEY', columns: { src: MysqlColumnName, ref: MysqlColumnRef }[] }
type ConstraintFormatted = ConstraintPrimaryKey | ConstraintUnique | ConstraintIndex | ConstraintForeignKey

function buildTableConstraints(constraints: RawConstraint[]): ConstraintFormatted[] {
    return Object.values(groupBy(constraints, c => c.constraint)).map(columns => {
        const first = columns[0]
        const sorted = columns.sort((a, b) => (a.index || 0) - (b.index || 0))
        if (first.type === 'FOREIGN KEY') {
            return {
                schema: first.schema,
                table: first.table,
                constraint: first.constraint,
                type: first.type,
                columns: sorted.map(c => ({
                    src: c.column,
                    ref: {schema: c.ref_schema || '', table: c.ref_table || '', column: c.ref_column || ''}
                }))
            }
        } else {
            return {
                schema: first.schema,
                table: first.table,
                constraint: first.constraint,
                type: first.type,
                columns: sorted.map(c => c.column)
            }
        }
    })
}

function handleError<T>(msg: string, value: T, ignoreErrors: boolean, logger: Logger) {
    return (err: any): Promise<T> => {
        if (ignoreErrors) {
            logger.warn(`${msg}. Ignoring...`)
            return Promise.resolve(value)
        } else {
            return Promise.reject(err)
        }
    }
}

function filterSchema(field: string, schema: MysqlSchemaName | undefined) {
    return `${field} ${schema ? `= '${schema}'` : `!= 'information_schema'`}`
}
