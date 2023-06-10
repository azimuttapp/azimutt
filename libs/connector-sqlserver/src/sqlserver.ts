import {
    groupBy,
    Logger,
    mapValues,
    removeSurroundingParentheses,
    removeUndefined,
    safeJsonParse,
    sequence
} from "@azimutt/utils";
import {AzimuttRelation, AzimuttSchema, AzimuttType} from "@azimutt/database-types";
import {schemaToColumns, ValueSchema, valuesToSchema} from "@azimutt/json-infer-schema";
import {Conn} from "./common";
import {buildColumnType} from "./helpers";

export type SqlserverSchema = { tables: SqlserverTable[], relations: AzimuttRelation[], types: AzimuttType[] }
export type SqlserverTable = { schema: SqlserverSchemaName, table: SqlserverTableName, view: boolean, columns: SqlserverColumn[], primaryKey: SqlserverPrimaryKey | null, uniques: SqlserverUnique[], indexes: SqlserverIndex[], checks: SqlserverCheck[], comment: string | null }
export type SqlserverColumn = { name: SqlserverColumnName, type: SqlserverColumnType, nullable: boolean, default: string | null, comment: string | null, schema: ValueSchema | null }
export type SqlserverPrimaryKey = { name: string | null, columns: SqlserverColumnName[] }
export type SqlserverUnique = { name: string, columns: SqlserverColumnName[], definition: string | null }
export type SqlserverIndex = { name: string, columns: SqlserverColumnName[], definition: string | null }
export type SqlserverCheck = { name: string, columns: SqlserverColumnName[], predicate: string | null }
export type SqlserverColumnRef = { schema: SqlserverSchemaName, table: SqlserverTableName, column: SqlserverColumnName }
export type SqlserverSchemaName = string
export type SqlserverTableName = string
export type SqlserverColumnName = string
export type SqlserverColumnType = string
export type SqlserverConstraintName = string
export type SqlserverTableId = string

export const getSchema = (schema: SqlserverSchemaName | undefined, sampleSize: number, logger: Logger) => async (conn: Conn): Promise<SqlserverSchema> => {
    const constraints = await getAllConstraints(conn, schema).then(constraints => mapValues(groupBy(constraints, toTableId), buildTableConstraints))
    const columns = await getColumns(conn, schema)
        .then(cols => enrichColumnsWithSchema(conn, cols, constraints, sampleSize))
        .then(cols => groupBy(cols, toTableId))
    const comments = await getTableComments(conn, schema).then(tables => groupBy(tables, toTableId))
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
                        default: col.column_default ? removeSurroundingParentheses(col.column_default) : null,
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
                checks: tableConstraints.filter((c): c is ConstraintCheck => c.type === 'CHECK').map(c => ({
                    name: c.constraint,
                    columns: c.columns,
                    predicate: c.definition ? removeSurroundingParentheses(c.definition) : null
                })) || [],
                comment: tableComments[0]?.comment || null
            }
        }).sort((a, b) => `${a.schema}.${a.table}`.localeCompare(`${b.schema}.${b.table}`)),
        relations: Object.values(constraints).flat().filter((c): c is ConstraintForeignKey => c.type === 'FOREIGN KEY').flatMap(c => c.columns.map(col => ({
            name: c.constraint,
            src: {schema: c.schema, table: c.table, column: col.src},
            ref: {schema: col.ref.schema, table: col.ref.table, column: col.ref.column}
        }))).sort((a, b) => a.name.localeCompare(b.name)),
        types: [] // TODO
    }
}

export function formatSchema(schema: SqlserverSchema, inferRelations: boolean): AzimuttSchema {
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

function toTableId<T extends { schema: string, table: string }>(value: T): SqlserverTableId {
    return `${value.schema}.${value.table}`
}

type RawColumn = {
    schema: SqlserverSchemaName
    table: SqlserverTableName
    table_kind: 'BASE TABLE' | 'VIEW'
    column: SqlserverColumnName
    column_type: SqlserverColumnType
    column_index: number
    column_default: string | null
    column_nullable: 'YES' | 'NO'
    column_comment: string
    column_schema?: ValueSchema
}

function getColumns(conn: Conn, schema: SqlserverSchemaName | undefined): Promise<RawColumn[]> {
    return conn.query<RawColumn>(
        `SELECT c.TABLE_SCHEMA                  AS "schema",
                c.TABLE_NAME                    AS "table",
                t.TABLE_TYPE                    AS table_kind,
                c.COLUMN_NAME                   AS "column",
                ${buildColumnType('c')}         AS column_type,
                c.ORDINAL_POSITION              AS column_index,
                c.COLUMN_DEFAULT                AS column_default,
                c.IS_NULLABLE                   AS column_nullable,
                (SELECT cc.value
                 FROM sys.columns sc
                          JOIN sys.objects st ON sc.object_id = st.object_id
                          JOIN sys.sysusers ss ON st.schema_id = ss.uid
                          JOIN sys.extended_properties cc
                               ON cc.major_id = sc.object_id AND cc.minor_id = sc.column_id AND
                                  cc.name = 'MS_Description'
                 WHERE ss.name = c.TABLE_SCHEMA
                   AND st.name = c.TABLE_NAME
                   AND sc.name = c.COLUMN_NAME) AS column_comment
         FROM information_schema.COLUMNS c
                  JOIN information_schema.TABLES t ON c.TABLE_SCHEMA = t.TABLE_SCHEMA AND c.TABLE_NAME = t.TABLE_NAME
         WHERE ${filterSchema('c.TABLE_SCHEMA', schema)};`
    )
}

function enrichColumnsWithSchema(conn: Conn, columns: RawColumn[], constraints: Record<SqlserverTableId, ConstraintFormatted[]>, sampleSize: number): Promise<RawColumn[]> {
    return sequence(columns, (c: RawColumn) => {
        if (c.column_type === 'nvarchar') {
            if (constraints[toTableId(c)]?.find(ct => ct.type === 'CHECK' && ct.schema == c.schema && ct.table == c.table && ct.columns.indexOf(c.column) >= 0 && ct.definition?.includes('isjson'))) {
                return getColumnSchema(conn, c.schema, c.table, c.column, sampleSize)
                    .then(column_schema => ({...c, column_schema}))
            }
        }
        return Promise.resolve(c)
    })
}

async function getColumnSchema(conn: Conn, schema: string, table: string, column: string, sampleSize: number): Promise<ValueSchema> {
    const sqlTable = `${schema ? `${schema}.` : ''}${table}`
    const rows = await conn.query(`SELECT TOP ${sampleSize} ${column} FROM ${sqlTable} WHERE ${column} IS NOT NULL;`)
    return valuesToSchema(rows.map(row => safeJsonParse(row[column] as string)))
}

type RawTable = {
    schema: SqlserverSchemaName
    table: SqlserverTableName
    comment: string
}

function getTableComments(conn: Conn, schema: SqlserverSchemaName | undefined): Promise<RawTable[]> {
    return conn.query<RawTable>(
        `SELECT s.name   AS "schema",
                t.name   AS "table",
                ep.value AS comment
         FROM sys.sysobjects t
                  JOIN sys.sysusers s ON s.uid = t.uid
                  JOIN sys.extended_properties ep ON ep.major_id = t.id AND ep.minor_id = 0 AND ep.name = 'MS_Description'
         WHERE (t.type = 'U' OR t.type = 'V') AND ep.value IS NOT NULL AND ${filterSchema('s.name', schema)};`
    )
}

type RawConstraint = {
    schema: SqlserverSchemaName
    table: SqlserverTableName
    constraint: SqlserverConstraintName
    type: 'PRIMARY KEY' | 'FOREIGN KEY' | 'UNIQUE' | 'INDEX' | 'CHECK'
    column?: SqlserverColumnName
    index?: number
    ref_schema?: SqlserverSchemaName
    ref_table?: SqlserverTableName
    ref_column?: SqlserverColumnName
    definition?: string
}

async function getAllConstraints(conn: Conn, schema: SqlserverSchemaName | undefined): Promise<RawConstraint[]> {
    return Promise.all([
        getPKsUniquesAndIndexes(conn, schema),
        getForeignKeys(conn, schema),
        getChecks(conn, schema),
    ]).then(constraints => constraints.flat())
}

function getPKsUniquesAndIndexes(conn: Conn, schema: SqlserverSchemaName | undefined): Promise<RawConstraint[]> {
    return conn.query<RawConstraint>(
        `SELECT OBJECT_SCHEMA_NAME(i.object_id)     AS "schema",
                OBJECT_NAME(i.object_id)            AS "table",
                i.name                              AS "constraint",
                CASE
                    WHEN OBJECTPROPERTY(OBJECT_ID(OBJECT_SCHEMA_NAME(i.object_id) + '.' + QUOTENAME(i.name)),
                                        'IsPrimaryKey') = 1
                        THEN 'PRIMARY KEY'
                    WHEN i.is_unique = 1
                        THEN 'UNIQUE'
                    ELSE 'INDEX' END                AS type,
                COL_NAME(i.object_id, ic.column_id) AS "column",
                ic.key_ordinal                      as "index"
         FROM sys.indexes i
                  JOIN sys.index_columns ic ON i.object_id = ic.object_id AND i.index_id = ic.index_id
         WHERE ${filterSchema('OBJECT_SCHEMA_NAME(i.object_id)', schema)};`
    )
}

function getForeignKeys(conn: Conn, schema: SqlserverSchemaName | undefined): Promise<RawConstraint[]> {
    return conn.query<RawConstraint>(
        `SELECT sch1.name                AS "schema",
                tab1.name                AS "table",
                obj.name                 AS "constraint",
                'FOREIGN KEY'            AS type,
                col1.name                AS "column",
                fkc.constraint_column_id AS "index",
                sch2.name                AS "ref_schema",
                tab2.name                AS "ref_table",
                col2.name                AS "ref_column"
         FROM sys.foreign_key_columns fkc
                  JOIN sys.objects obj ON obj.object_id = fkc.constraint_object_id
                  JOIN sys.tables tab1 ON tab1.object_id = fkc.parent_object_id
                  JOIN sys.schemas sch1 ON tab1.schema_id = sch1.schema_id
                  JOIN sys.columns col1 ON col1.column_id = parent_column_id AND col1.object_id = tab1.object_id
                  JOIN sys.tables tab2 ON tab2.object_id = fkc.referenced_object_id
                  JOIN sys.schemas sch2 ON tab2.schema_id = sch2.schema_id
                  JOIN sys.columns col2 ON col2.column_id = referenced_column_id AND col2.object_id = tab2.object_id
         WHERE ${filterSchema('sch1.name', schema)};`
    )
}

function getChecks(conn: Conn, schema: SqlserverSchemaName | undefined): Promise<RawConstraint[]> {
    return conn.query<RawConstraint>(
        `SELECT SCHEMA_NAME(t.schema_id) AS "schema",
                t.name                   AS "table",
                con.name                 AS "constraint",
                'CHECK'                  AS type,
                c.name                   AS "column",
                con.definition
         FROM sys.check_constraints con
                  LEFT OUTER JOIN sys.objects t ON con.parent_object_id = t.object_id
                  LEFT OUTER JOIN sys.all_columns c
                                  ON con.parent_column_id = c.column_id AND con.parent_object_id = c.object_id
         WHERE con.is_disabled = 'false'
           AND ${filterSchema('SCHEMA_NAME(t.schema_id)', schema)};`
    )
}

type ConstraintBase = { schema: SqlserverSchemaName, table: SqlserverTableName, constraint: SqlserverConstraintName }
type ConstraintPrimaryKey = ConstraintBase & { type: 'PRIMARY KEY', columns: SqlserverColumnName[] }
type ConstraintForeignKey = ConstraintBase & { type: 'FOREIGN KEY', columns: { src: SqlserverColumnName, ref: SqlserverColumnRef }[] }
type ConstraintUnique = ConstraintBase & { type: 'UNIQUE', columns: SqlserverColumnName[] }
type ConstraintIndex = ConstraintBase & { type: 'INDEX', columns: SqlserverColumnName[] }
type ConstraintCheck = ConstraintBase & { type: 'CHECK', columns: SqlserverColumnName[], definition?: string }
type ConstraintFormatted = ConstraintPrimaryKey | ConstraintForeignKey | ConstraintUnique | ConstraintIndex | ConstraintCheck

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
                    src: c.column || '',
                    ref: {schema: c.ref_schema || '', table: c.ref_table || '', column: c.ref_column || ''}
                })).filter(c => !!c.src)
            }
        } else if(first.type === 'CHECK') {
            return {
                schema: first.schema,
                table: first.table,
                constraint: first.constraint,
                type: first.type,
                columns: sorted.map(c => c.column || '').filter(c => !!c),
                definition: first.definition
            }
        } else {
            return {
                schema: first.schema,
                table: first.table,
                constraint: first.constraint,
                type: first.type,
                columns: sorted.map(c => c.column || '').filter(c => !!c)
            }
        }
    })
}

function filterSchema(field: string, schema: SqlserverSchemaName | undefined) {
    return `${field} ${schema ? `= '${schema}'` : `NOT IN ('information_schema', 'sys')`}`
}
