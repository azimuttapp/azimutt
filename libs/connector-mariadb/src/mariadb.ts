import {groupBy, Logger, mapValues, mergeBy, removeUndefined, sequence} from "@azimutt/utils";
import {AzimuttRelation, AzimuttSchema, AzimuttType} from "@azimutt/database-types";
import {schemaToColumns, ValueSchema, valuesToSchema} from "@azimutt/json-infer-schema";
import {Conn} from "./common";

export type MariadbSchema = { tables: MariadbTable[], relations: AzimuttRelation[], types: AzimuttType[] }
export type MariadbTable = { schema: MariadbSchemaName, table: MariadbTableName, view: boolean, columns: MariadbColumn[], primaryKey: MariadbPrimaryKey | null, uniques: MariadbUnique[], indexes: MariadbIndex[], checks: MariadbCheck[], comment: string | null }
export type MariadbColumn = { name: MariadbColumnName, type: MariadbColumnType, nullable: boolean, default: string | null, comment: string | null, schema: ValueSchema | null }
export type MariadbPrimaryKey = { name: string | null, columns: MariadbColumnName[] }
export type MariadbUnique = { name: string, columns: MariadbColumnName[], definition: string | null }
export type MariadbIndex = { name: string, columns: MariadbColumnName[], definition: string | null }
export type MariadbCheck = { name: string, columns: MariadbColumnName[], predicate: string | null }
export type MariadbColumnRef = { schema: MariadbSchemaName, table: MariadbTableName, column: MariadbColumnName }
export type MariadbSchemaName = string
export type MariadbTableName = string
export type MariadbColumnName = string
export type MariadbColumnType = string
export type MariadbConstraintName = string
export type MariadbTableId = string

export const getSchema = (schema: MariadbSchemaName | undefined, sampleSize: number, logger: Logger) => async (conn: Conn): Promise<MariadbSchema> => {
    const columns = await getColumns(conn, schema)
        .then(cols => enrichColumnsWithSchema(conn, cols, sampleSize))
        .then(cols => groupBy(cols, toTableId))
    const comments = await getTableComments(conn, schema).then(tables => groupBy(tables, toTableId))
    const constraints = await getAllConstraints(conn, schema).then(constraints => mapValues(groupBy(constraints, toTableId), buildTableConstraints))
    return {
        tables: Object.entries(columns).map(([tableId, columns]) => {
            const tableConstraints = constraints[tableId] || []
            const tableComments = comments[tableId] || []
            return {
                schema: columns[0].schema,
                table: columns[0].table,
                view: columns[0].table_kind === 'VIEW',
                columns: columns
                    .sort((a, b) => Number(a.column_index - b.column_index))
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

export function formatSchema(schema: MariadbSchema, inferRelations: boolean): AzimuttSchema {
    // FIXME: handle inferRelations
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

function toTableId<T extends { schema: string, table: string }>(value: T): MariadbTableId {
    return `${value.schema}.${value.table}`
}

type RawColumn = {
    schema: MariadbSchemaName
    table: MariadbTableName
    table_kind: 'BASE TABLE' | 'VIEW'
    column: MariadbColumnName
    column_type: MariadbColumnType
    column_index: number
    column_default: string | null
    column_nullable: 'YES' | 'NO'
    column_comment: string
    column_schema?: ValueSchema
}

function getColumns(conn: Conn, schema: MariadbSchemaName | undefined): Promise<RawColumn[]> {
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
         ORDER BY "schema", "table", column_index;`
    )
}

function enrichColumnsWithSchema(conn: Conn, columns: RawColumn[], sampleSize: number): Promise<RawColumn[]> {
    return sequence(columns, c => {
        if (c.column_type === 'jsonb') {
            return getColumnSchema(conn, c.schema, c.table, c.column, sampleSize)
                .then(column_schema => ({...c, column_schema}))
        } else {
            return Promise.resolve(c)
        }
    })
}

async function getColumnSchema(conn: Conn, schema: string, table: string, column: string, sampleSize: number): Promise<ValueSchema> {
    const sqlTable = `${schema ? `${schema}.` : ''}${table}`
    const rows = await conn.query(`SELECT ${column} FROM ${sqlTable} WHERE ${column} IS NOT NULL LIMIT ${sampleSize};`)
    return valuesToSchema(rows.map(row => row[column]))
}

type RawTable = {
    schema: MariadbSchemaName
    table: MariadbTableName
    comment: string
}

function getTableComments(conn: Conn, schema: MariadbSchemaName | undefined): Promise<RawTable[]> {
    return conn.query<RawTable>(
        `SELECT TABLE_SCHEMA  AS "schema",
                TABLE_NAME    AS "table",
                TABLE_COMMENT AS comment
         FROM information_schema.TABLES
         WHERE TABLE_COMMENT != ''
           AND TABLE_COMMENT != 'VIEW'
           AND ${filterSchema('TABLE_SCHEMA', schema)};`
    )
}

type RawConstraint = {
    schema: MariadbSchemaName
    table: MariadbTableName
    constraint: MariadbConstraintName
    column: MariadbColumnName
    type: 'PRIMARY KEY' | 'UNIQUE' | 'FOREIGN KEY' | 'INDEX'
    index?: bigint
    ref_schema?: MariadbSchemaName
    ref_table?: MariadbTableName
    ref_column?: MariadbColumnName
}

async function getAllConstraints(conn: Conn, schema: MariadbSchemaName | undefined): Promise<RawConstraint[]> {
    const [indexes, constraints] = await Promise.all([getIndexes(conn, schema), getConstraints(conn, schema)])
    return mergeBy(indexes, constraints, c => `${c.schema}.${c.table}.${c.constraint}.${c.column}`)
}

function getIndexes(conn: Conn, schema: MariadbSchemaName | undefined): Promise<RawConstraint[]> {
    return conn.query<RawConstraint>(
        `SELECT INDEX_SCHEMA AS "schema",
                TABLE_NAME   AS "table",
                INDEX_NAME   AS "constraint",
                COLUMN_NAME  AS "column",
                SEQ_IN_INDEX AS "index",
                "INDEX"      AS type
         FROM information_schema.STATISTICS
         WHERE ${filterSchema('INDEX_SCHEMA', schema)};`
    )
}

function getConstraints(conn: Conn, schema: MariadbSchemaName | undefined): Promise<RawConstraint[]> {
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
         WHERE ${filterSchema('c.CONSTRAINT_SCHEMA', schema)};`)
}

type ConstraintBase = { schema: MariadbSchemaName, table: MariadbTableName, constraint: MariadbConstraintName }
type ConstraintPrimaryKey = ConstraintBase & { type: 'PRIMARY KEY', columns: MariadbColumnName[] }
type ConstraintUnique = ConstraintBase & { type: 'UNIQUE', columns: MariadbColumnName[] }
type ConstraintIndex = ConstraintBase & { type: 'INDEX', columns: MariadbColumnName[] }
type ConstraintForeignKey = ConstraintBase & { type: 'FOREIGN KEY', columns: { src: MariadbColumnName, ref: MariadbColumnRef }[] }
type ConstraintFormatted = ConstraintPrimaryKey | ConstraintUnique | ConstraintIndex | ConstraintForeignKey

function buildTableConstraints(constraints: RawConstraint[]): ConstraintFormatted[] {
    return Object.values(groupBy(constraints, c => c.constraint)).map(columns => {
        const first = columns[0]
        const sorted = columns.sort((a, b) => Number((a.index || BigInt(0)) - (b.index || BigInt(0))))
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

function filterSchema(field: string, schema: MariadbSchemaName | undefined) {
    return `${field} ${schema ? `= '${schema}'` : `NOT IN ('information_schema', 'performance_schema', 'sys', 'sky', 'mysql')`}`
}
