import {
    groupBy,
    Logger,
    mapValues,
    mapValuesAsync,
    removeSurroundingParentheses,
    removeUndefined,
    safeJsonParse,
    sequence
} from "@azimutt/utils";
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

export type SqlserverSchemaOpts = {logger: Logger, schema: SqlserverSchemaName | undefined, sampleSize: number, inferRelations: boolean, ignoreErrors: boolean}
export const getSchema = ({logger, schema, sampleSize, inferRelations, ignoreErrors}: SqlserverSchemaOpts) => async (conn: Conn): Promise<SqlserverSchema> => {
    const constraints = await getAllConstraints(conn, schema, ignoreErrors, logger).then(constraints => mapValues(groupBy(constraints, toTableId), buildTableConstraints))
    const columns = await getColumns(conn, schema, ignoreErrors, logger)
        .then(cols => groupBy(cols, toTableId))
        .then(cols => mapValuesAsync(cols, tableCols => enrichColumnsWithSchema(conn, tableCols, constraints, sampleSize, inferRelations, ignoreErrors, logger)))
    const comments = await getComments(conn, schema, ignoreErrors, logger).then(comments => groupBy(comments, toTableId))
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
                        comment: tableComments.find(c => c.column === col.column)?.comment || null,
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
                comment: tableComments.find(c => !c.column)?.comment || null
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
    column_schema?: ValueSchema
}

function getColumns(conn: Conn, schema: SqlserverSchemaName | undefined, ignoreErrors: boolean, logger: Logger): Promise<RawColumn[]> {
    return conn.query<RawColumn>(`
        SELECT c.TABLE_SCHEMA          AS "schema",
               c.TABLE_NAME            AS "table",
               t.TABLE_TYPE            AS table_kind,
               c.COLUMN_NAME           AS "column",
               ${buildColumnType('c')} AS column_type,
               c.ORDINAL_POSITION      AS column_index,
               c.COLUMN_DEFAULT        AS column_default,
               c.IS_NULLABLE           AS column_nullable
        FROM information_schema.COLUMNS c
                 JOIN information_schema.TABLES t ON c.TABLE_SCHEMA = t.TABLE_SCHEMA AND c.TABLE_NAME = t.TABLE_NAME
        WHERE ${filterSchema('c.TABLE_SCHEMA', schema)}
        ORDER BY "schema", "table", column_index;`, [], 'getColumns'
    ).catch(handleError(`Failed to get columns${schema ? ` for schema '${schema}'` : ''}`, [], ignoreErrors, logger))
}

function enrichColumnsWithSchema(conn: Conn, tableCols: RawColumn[], constraints: Record<SqlserverTableId, ConstraintFormatted[]>, sampleSize: number, inferRelations: boolean, ignoreErrors: boolean, logger: Logger): Promise<RawColumn[]> {
    const colNames = tableCols.map(c => c.column)
    return sequence(tableCols, async c => {
        if (sampleSize > 0 && c.column_type === 'nvarchar' && constraints[toTableId(c)]?.find(ct => ct.type === 'CHECK' && ct.schema == c.schema && ct.table == c.table && ct.columns.indexOf(c.column) >= 0 && ct.definition?.includes('isjson'))) {
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
    return conn.query(`SELECT TOP ${sampleSize} ${column} FROM ${sqlTable} WHERE ${column} IS NOT NULL;`, [], 'getColumnSchema')
        .then(rows => valuesToSchema(rows.map(row => safeJsonParse(row[column] as string))))
        .catch(handleError(`Failed to infer schema for column '${column}' of table '${schema ? schema + '.' : ''}${table}'`, valuesToSchema([]), ignoreErrors, logger))
}

type RawComment = {
    schema: SqlserverSchemaName
    table: SqlserverTableName
    column?: SqlserverColumnName
    comment: string
}

function getComments(conn: Conn, schema: SqlserverSchemaName | undefined, ignoreErrors: boolean, logger: Logger): Promise<RawComment[]> {
    // https://learn.microsoft.com/sql/relational-databases/system-catalog-views/extended-properties-catalog-views-sys-extended-properties
    // https://learn.microsoft.com/sql/relational-databases/system-catalog-views/sys-objects-transact-sql
    // https://learn.microsoft.com/sql/relational-databases/system-compatibility-views/sys-sysusers-transact-sql
    // https://learn.microsoft.com/sql/relational-databases/system-catalog-views/sys-columns-transact-sql
    return conn.query<RawComment>(`
        SELECT s.name  AS "schema",
               t.name  AS "table",
               c.name  AS "column",
               p.value AS comment
        FROM sys.extended_properties p
                 JOIN sys.objects t ON t.object_id = p.major_id
                 JOIN sys.sysusers s ON s.uid = t.schema_id
                 LEFT OUTER JOIN sys.columns c ON c.object_id = p.major_id AND c.column_id = p.minor_id
        WHERE p.class = 1
          AND p.name = 'MS_Description'
          AND p.value IS NOT NULL
          AND t.type IN ('S', 'IT', 'U', 'V')
          AND ${filterSchema('s.name', schema)};`, [], 'getComments'
    ).catch(handleError(`Failed to get comments${schema ? ` for schema '${schema}'` : ''}`, [], ignoreErrors, logger))
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

async function getAllConstraints(conn: Conn, schema: SqlserverSchemaName | undefined, ignoreErrors: boolean, logger: Logger): Promise<RawConstraint[]> {
    return Promise.all([
        getPKsUniquesAndIndexes(conn, schema, ignoreErrors, logger),
        getForeignKeys(conn, schema, ignoreErrors, logger),
        getChecks(conn, schema, ignoreErrors, logger),
    ]).then(constraints => constraints.flat())
}

function getPKsUniquesAndIndexes(conn: Conn, schema: SqlserverSchemaName | undefined, ignoreErrors: boolean, logger: Logger): Promise<RawConstraint[]> {
    return conn.query<RawConstraint>(`
        SELECT OBJECT_SCHEMA_NAME(i.object_id)     AS "schema",
               OBJECT_NAME(i.object_id)            AS "table",
               i.name                              AS "constraint",
               CASE
                   WHEN OBJECTPROPERTY(OBJECT_ID(OBJECT_SCHEMA_NAME(i.object_id) + '.' + QUOTENAME(i.name)), 'IsPrimaryKey') = 1
                       THEN 'PRIMARY KEY'
                   WHEN i.is_unique = 1
                       THEN 'UNIQUE'
                   ELSE 'INDEX' END                AS type,
               COL_NAME(i.object_id, ic.column_id) AS "column",
               ic.key_ordinal                      as "index"
        FROM sys.indexes i
                 JOIN sys.index_columns ic ON i.object_id = ic.object_id AND i.index_id = ic.index_id
        WHERE ${filterSchema('OBJECT_SCHEMA_NAME(i.object_id)', schema)};`, [], 'getPKsUniquesAndIndexes'
    ).catch(handleError(`Failed to get constraints (pks, uniques & indexes)${schema ? ` for schema '${schema}'` : ''}`, [], ignoreErrors, logger))
}

function getForeignKeys(conn: Conn, schema: SqlserverSchemaName | undefined, ignoreErrors: boolean, logger: Logger): Promise<RawConstraint[]> {
    return conn.query<RawConstraint>(`
        SELECT sch1.name                AS "schema",
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
        WHERE ${filterSchema('sch1.name', schema)};`, [], 'getForeignKeys'
    ).catch(handleError(`Failed to get foreign keys${schema ? ` for schema '${schema}'` : ''}`, [], ignoreErrors, logger))
}

function getChecks(conn: Conn, schema: SqlserverSchemaName | undefined, ignoreErrors: boolean, logger: Logger): Promise<RawConstraint[]> {
    return conn.query<RawConstraint>(`
        SELECT SCHEMA_NAME(t.schema_id) AS "schema",
               t.name                   AS "table",
               con.name                 AS "constraint",
               'CHECK'                  AS type,
               c.name                   AS "column",
               con.definition
        FROM sys.check_constraints con
                 LEFT OUTER JOIN sys.objects t ON con.parent_object_id = t.object_id
                 LEFT OUTER JOIN sys.all_columns c ON con.parent_column_id = c.column_id AND con.parent_object_id = c.object_id
        WHERE con.is_disabled = 'false' AND ${filterSchema('SCHEMA_NAME(t.schema_id)', schema)};`, [], 'getChecks'
    ).catch(handleError(`Failed to get checks${schema ? ` for schema '${schema}'` : ''}`, [], ignoreErrors, logger))
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

function filterSchema(field: string, schema: SqlserverSchemaName | undefined) {
    return `${field} ${schema ? `= '${schema}'` : `NOT IN ('information_schema', 'sys')`}`
}
