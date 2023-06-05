import {Connection, RowDataPacket} from "mysql2/promise";
import {groupBy, Logger, mapValues, mergeBy, removeUndefined, sequence} from "@azimutt/utils";
import {AzimuttRelation, AzimuttSchema, AzimuttType, DatabaseUrlParsed} from "@azimutt/database-types";
import {schemaToColumns, ValueSchema, valuesToSchema} from "@azimutt/json-infer-schema";
import {connect, query} from "./connect";

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

export async function getSchema(application: string, url: DatabaseUrlParsed, schema: MysqlSchemaName | undefined, sampleSize: number, logger: Logger): Promise<MysqlSchema> {
    return connect(application, url, async conn => {
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
    })
}

export function formatSchema(schema: MysqlSchema, inferRelations: boolean): AzimuttSchema {
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

function toTableId<T extends { schema: string, table: string }>(value: T): MysqlTableId {
    return `${value.schema}.${value.table}`
}

interface RawColumn {
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

async function getColumns(conn: Connection, schema: MysqlSchemaName | undefined): Promise<RawColumn[]> {
    return query<RawColumn>(conn,
        `SELECT c.TABLE_SCHEMA     as "schema",
                c.TABLE_NAME       as "table",
                t.TABLE_TYPE       as table_kind,
                c.COLUMN_NAME      as "column",
                c.COLUMN_TYPE      as column_type,
                c.ORDINAL_POSITION as column_index,
                c.COLUMN_DEFAULT   as column_default,
                c.IS_NULLABLE      as column_nullable,
                c.COLUMN_COMMENT   as column_comment
         FROM information_schema.COLUMNS c
                  JOIN information_schema.TABLES t ON c.TABLE_SCHEMA = t.TABLE_SCHEMA AND c.TABLE_NAME = t.TABLE_NAME
         WHERE ${filterSchema('c.TABLE_SCHEMA', schema)}
         ORDER BY "schema", "table", column_index;`
    )
}

function enrichColumnsWithSchema(conn: Connection, columns: RawColumn[], sampleSize: number): Promise<RawColumn[]> {
    return sequence(columns, c => {
        if (c.column_type === 'jsonb') {
            return getColumnSchema(conn, c.schema, c.table, c.column, sampleSize)
                .then(column_schema => ({...c, column_schema}))
        } else {
            return Promise.resolve(c)
        }
    })
}

async function getColumnSchema(conn: Connection, schema: string, table: string, column: string, sampleSize: number): Promise<ValueSchema> {
    const sqlTable = `${schema ? `${schema}.` : ''}${table}`
    const [result] = await conn.query<RowDataPacket[]>(`SELECT ${column} FROM ${sqlTable} WHERE ${column} IS NOT NULL LIMIT ${sampleSize};`)
    return valuesToSchema(result.map(r => r[column]))
}

interface RawTable {
    schema: MysqlSchemaName
    table: MysqlTableName
    comment: string
}

async function getTableComments(conn: Connection, schema: MysqlSchemaName | undefined): Promise<RawTable[]> {
    return query<RawTable>(conn,
        `SELECT TABLE_SCHEMA  as "schema",
                TABLE_NAME    as "table",
                TABLE_COMMENT as comment
         FROM information_schema.TABLES
         WHERE TABLE_COMMENT != ''
           AND TABLE_COMMENT != 'VIEW'
           AND ${filterSchema('TABLE_SCHEMA', schema)};`
    )
}

interface RawConstraint {
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

async function getAllConstraints(conn: Connection, schema: MysqlSchemaName | undefined): Promise<RawConstraint[]> {
    const [indexes, constraints] = await Promise.all([getIndexes(conn, schema), getConstraints(conn, schema)])
    return mergeBy(indexes, constraints, c => `${c.schema}.${c.table}.${c.constraint}.${c.column}`)
}

async function getIndexes(conn: Connection, schema: MysqlSchemaName | undefined): Promise<RawConstraint[]> {
    return query<RawConstraint>(conn,
        `SELECT INDEX_SCHEMA as "schema",
                TABLE_NAME   as "table",
                INDEX_NAME   as "constraint",
                COLUMN_NAME  as "column",
                SEQ_IN_INDEX as "index",
                "INDEX"      as type
         FROM information_schema.STATISTICS
         WHERE ${filterSchema('INDEX_SCHEMA', schema)};`
    )
}

async function getConstraints(conn: Connection, schema: MysqlSchemaName | undefined): Promise<RawConstraint[]> {
    return query<RawConstraint>(conn,
        `SELECT c.CONSTRAINT_SCHEMA       as "schema",
                c.TABLE_NAME              as "table",
                c.CONSTRAINT_NAME         as "constraint",
                u.COLUMN_NAME             as "column",
                c.CONSTRAINT_TYPE         as type,
                u.REFERENCED_TABLE_SCHEMA as ref_schema,
                u.REFERENCED_TABLE_NAME   as ref_table,
                u.REFERENCED_COLUMN_NAME  as ref_column
         FROM information_schema.TABLE_CONSTRAINTS c
                  JOIN information_schema.KEY_COLUMN_USAGE u
                       ON c.CONSTRAINT_SCHEMA = u.CONSTRAINT_SCHEMA AND c.TABLE_NAME = u.TABLE_NAME AND
                          c.CONSTRAINT_NAME = u.CONSTRAINT_NAME
         WHERE ${filterSchema('c.CONSTRAINT_SCHEMA', schema)};`)
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

function filterSchema(field: string, schema: MysqlSchemaName | undefined) {
    return `${field} ${schema ? `= '${schema}'` : `!= 'information_schema'`}`
}
