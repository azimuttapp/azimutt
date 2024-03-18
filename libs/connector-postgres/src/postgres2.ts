import {groupBy, Logger, mapValuesAsync, removeUndefined, sequence, zip} from "@azimutt/utils";
import {
    AzimuttSchema,
    ColumnName,
    isPolymorphicColumn,
    SchemaName,
    schemaToColumns,
    TableName,
    ValueSchema,
    valuesToSchema
} from "@azimutt/database-types";
import {Conn} from "./common";
import {buildSqlColumn, buildSqlTable} from "./helpers";

export type PostgresSchema = { tables: PostgresTable[], relations: PostgresRelation[], types: PostgresType[] }
export type PostgresTable = { schema: PostgresSchemaName, table: PostgresTableName, view: boolean, columns: PostgresColumn[], primaryKey: PostgresPrimaryKey | null, uniques: PostgresUnique[], indexes: PostgresIndex[], checks: PostgresCheck[], comment: string | null }
export type PostgresColumn = { name: PostgresColumnName, type: PostgresColumnType, nullable: boolean, default: string | null, comment: string | null, values: string[] | null, schema: ValueSchema | null }
export type PostgresPrimaryKey = { name: string | null, columns: PostgresColumnName[] }
export type PostgresUnique = { name: string, columns: PostgresColumnName[], definition: string | null }
export type PostgresIndex = { name: string, columns: PostgresColumnName[], definition: string | null }
export type PostgresCheck = { name: string, columns: PostgresColumnName[], predicate: string | null }
export type PostgresRelation = { name: PostgresRelationName, src: PostgresTableRef, ref: PostgresTableRef, columns: PostgresColumnLink[] }
export type PostgresTableRef = { schema: PostgresSchemaName, table: PostgresTableName }
export type PostgresColumnLink = { src: PostgresColumnName, ref: PostgresColumnName }
export type PostgresType = { schema: PostgresSchemaName, name: PostgresTypeName, values: string[] | null }
export type PostgresSchemaName = string
export type PostgresTableName = string
export type PostgresColumnName = string
export type PostgresColumnType = string
export type PostgresRelationName = string
export type PostgresTypeName = string
export type PostgresTableId = string

export type PostgresSchemaOpts = {logger: Logger, schema: PostgresSchemaName | undefined, sampleSize: number, inferRelations: boolean, ignoreErrors: boolean}
export const getSchema = ({logger, schema, sampleSize, inferRelations, ignoreErrors}: PostgresSchemaOpts) => async (conn: Conn): Promise<PostgresSchema> => {
    const columns = await getColumns(conn, schema, ignoreErrors, logger)
        .then(cols => groupBy(cols, toTableId))
        .then(cols => mapValuesAsync(cols, tableCols => enrichColumnsWithSchema(conn, tableCols, sampleSize, inferRelations, ignoreErrors, logger)))
    const columnsByIndex: { [tableId: string]: { [columnIndex: number]: RawColumn } } = Object.keys(columns).reduce((acc, tableId) => ({
        ...acc,
        [tableId]: columns[tableId].reduce((acc, c) => ({...acc, [c.column_index]: c}), {})
    }), {})
    const getColumnName = (tableId: string) => (columnIndex: number): string => columnsByIndex[tableId]?.[columnIndex]?.column_name || 'unknown'
    const constraints = await getConstraints(conn, schema, ignoreErrors, logger).then(cols => groupBy(cols, toTableId))
    const indexes = await getIndexes(conn, schema, ignoreErrors, logger).then(cols => groupBy(cols, toTableId))
    const comments = await getComments(conn, schema, ignoreErrors, logger).then(cols => groupBy(cols, toTableId))
    const relations = await getRelations(conn, schema, ignoreErrors, logger)
    const types = await getTypes(conn, schema, ignoreErrors, logger)
    return {
        tables: Object.entries(columns).map(([tableId, columns]) => {
            const tableConstraints = constraints[tableId] || []
            const tableIndexes = indexes[tableId] || []
            const tableComments = comments[tableId] || []
            return {
                schema: columns[0].table_schema,
                table: columns[0].table_name,
                view: columns[0].table_kind !== 'r',
                columns: columns
                    .sort((a, b) => a.column_index - b.column_index)
                    .map(col => ({
                        name: col.column_name,
                        type: col.column_type,
                        nullable: col.column_nullable,
                        default: col.column_default,
                        comment: tableComments.find(c => c.column_name === col.column_name)?.comment || null,
                        values: col.column_values || null,
                        schema: col.column_schema || null
                    })),
                primaryKey: tableConstraints.filter(c => c.constraint_type === 'p').map(c => ({
                    name: c.constraint_name,
                    columns: c.columns.map(getColumnName(tableId))
                }))[0] || null,
                uniques: tableIndexes.filter(i => i.is_unique).map(i => ({
                    name: i.index_name,
                    columns: i.columns.map(getColumnName(tableId)),
                    definition: i.definition
                })),
                indexes: tableIndexes.filter(i => !i.is_unique).map(i => ({
                    name: i.index_name,
                    columns: i.columns.map(getColumnName(tableId)),
                    definition: i.definition
                })),
                checks: tableConstraints.filter(c => c.constraint_type === 'c').map(c => ({
                    name: c.constraint_name,
                    columns: c.columns.map(getColumnName(tableId)),
                    predicate: c.definition.replace(/^CHECK/, '').trim()
                })),
                comment: tableComments.find(c => c.column_name === null)?.comment || null
            }
        }),
        relations: relations.map(r => ({
            name: r.constraint_name,
            src: {schema: r.table_schema, table: r.table_name},
            ref: {schema: r.target_schema, table: r.target_table},
            columns: zip(r.columns.map(getColumnName(toTableId(r))), r.target_columns.map(getColumnName(toTableId({
                table_schema: r.target_schema,
                table_name: r.target_table
            })))).map(([src, ref]) => ({src, ref}))
        })),
        types: types.map(t => ({
            schema: t.type_schema,
            name: t.type_name,
            values: t.type_kind === 'e' ? t.enum_values : null
        }))
    }
}

export function formatSchema(schema: PostgresSchema): AzimuttSchema {
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
                values: c.values && c.values.length > 0 ? c.values : undefined,
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
        relations: schema.relations.flatMap(r => r.columns.map(c => ({
            name: r.name,
            src: {schema: r.src.schema, table: r.src.table, column: c.src},
            ref: {schema: r.ref.schema, table: r.ref.table, column: c.ref}
        }))),
        types: schema.types.map(t => t.values ? {
            schema: t.schema,
            name: t.name,
            values: t.values
        } : {
            schema: t.schema,
            name: t.name,
            definition: ''
        })
    }
}

// 👇️ Private functions, some are exported only for tests
// If you use them, beware of breaking changes!

function toTableId<T extends { table_schema: string, table_name: string }>(value: T): PostgresTableId {
    return `${value.table_schema}.${value.table_name}`
}

export type RawColumn = {
    table_schema: string
    table_name: string
    table_kind: 'r' | 'v' | 'm' // r: table, v: view, m: materialized view
    column_name: string
    column_type: string
    column_index: number
    column_default: string | null
    column_nullable: boolean
    column_values?: string[]
    column_schema?: ValueSchema
}

async function getColumns(conn: Conn, schema: PostgresSchemaName | undefined, ignoreErrors: boolean, logger: Logger): Promise<RawColumn[]> {
    // https://www.postgresql.org/docs/current/catalog-pg-attribute.html: stores information about table columns. There will be exactly one row for every column in every table in the database.
    // https://www.postgresql.org/docs/current/catalog-pg-class.html: catalogs tables and most everything else that has columns or is otherwise similar to a table. This includes indexes (but see also pg_index), sequences (but see also pg_sequence), views, materialized views, composite types, and TOAST tables; see relkind.
    // https://www.postgresql.org/docs/current/catalog-pg-namespace.html: stores namespaces. A namespace is the structure underlying SQL schemas: each namespace can have a separate collection of relations, types, etc. without name conflicts.
    // https://www.postgresql.org/docs/current/catalog-pg-attrdef.html: stores column default values.
    // system columns have `attnum` < 0, avoid them
    // deleted columns have `atttypid` at 0, avoid them
    return conn.query<RawColumn>(`
        SELECT n.nspname                            AS table_schema
             , c.relname                            AS table_name
             , c.relkind                            AS table_kind
             , a.attname                            AS column_name
             , format_type(a.atttypid, a.atttypmod) AS column_type
             , a.attnum                             AS column_index
             , pg_get_expr(d.adbin, d.adrelid)      AS column_default
             , NOT a.attnotnull                     AS column_nullable
        FROM pg_attribute a
                 JOIN pg_class c ON c.oid = a.attrelid
                 JOIN pg_namespace n ON n.oid = c.relnamespace
                 LEFT OUTER JOIN pg_attrdef d ON d.adrelid = c.oid AND d.adnum = a.attnum
        WHERE c.relkind IN ('r', 'v', 'm')
          AND a.attnum > 0
          AND a.atttypid != 0
          AND ${filterSchema('n.nspname', schema)}
        ORDER BY table_schema, table_name, column_index;`, [], 'getColumns'
    ).catch(handleError(`Failed to get columns${schema ? ` for schema '${schema}'` : ''}`, [], ignoreErrors, logger))
}

function enrichColumnsWithSchema(conn: Conn, tableCols: RawColumn[], sampleSize: number, inferRelations: boolean, ignoreErrors: boolean, logger: Logger): Promise<RawColumn[]> {
    const colNames = tableCols.map(c => c.column_name)
    return sequence(tableCols, async c => {
        if (sampleSize > 0 && c.column_type === 'jsonb') {
            return getColumnSchema(conn, c.table_schema, c.table_name, c.column_name, sampleSize, ignoreErrors, logger).then(column_schema => ({...c, column_schema}))
        } else if (inferRelations && isPolymorphicColumn(c.column_name, colNames)) {
            return getColumnDistinctValues(conn, c.table_schema, c.table_name, c.column_name, ignoreErrors, logger).then(column_values => ({...c, column_values}))
        } else {
            return c
        }
    })
}

async function getColumnSchema(conn: Conn, schema: SchemaName, table: TableName, column: ColumnName, sampleSize: number, ignoreErrors: boolean, logger: Logger): Promise<ValueSchema> {
    const sqlTable = buildSqlTable(schema, table)
    const sqlColumn = buildSqlColumn(column)
    return conn.query(`SELECT ${sqlColumn} FROM ${sqlTable} WHERE ${sqlColumn} IS NOT NULL LIMIT ${sampleSize};`, [], 'getColumnSchema')
        .then(rows => valuesToSchema(rows.map(row => row[column])))
        .catch(handleError(`Failed to infer schema for column '${column}' of table '${schema ? schema + '.' : ''}${table}'`, valuesToSchema([]), ignoreErrors, logger))
}

async function getColumnDistinctValues(conn: Conn, schema: SchemaName, table: TableName, column: ColumnName, ignoreErrors: boolean, logger: Logger): Promise<string[]> {
    const sqlTable = buildSqlTable(schema, table)
    const sqlColumn = buildSqlColumn(column)
    return conn.query<{value: string}>(`SELECT DISTINCT ${sqlColumn} as value FROM ${sqlTable} WHERE ${sqlColumn} IS NOT NULL ORDER BY value LIMIT 30;`, [], 'getColumnDistinctValues')
        .then(rows => rows.map(v => v.value?.toString()))
        .catch(handleError(`Failed to get distinct values for column '${column}' of table '${schema ? schema + '.' : ''}${table}'`, [], ignoreErrors, logger))
}

type RawConstraint = {
    constraint_type: 'p' | 'c' // p: primary key, c: check
    constraint_name: string
    table_schema: string
    table_name: string
    columns: number[]
    definition: string
}

async function getConstraints(conn: Conn, schema: PostgresSchemaName | undefined, ignoreErrors: boolean, logger: Logger): Promise<RawConstraint[]> {
    // https://www.postgresql.org/docs/current/catalog-pg-constraint.html: stores check, primary key, unique, foreign key, and exclusion constraints on tables. Not-null constraints are represented in the pg_attribute catalog, not here.
    // https://www.postgresql.org/docs/current/catalog-pg-class.html: catalogs tables and most everything else that has columns or is otherwise similar to a table. This includes indexes (but see also pg_index), sequences (but see also pg_sequence), views, materialized views, composite types, and TOAST tables; see relkind.
    // https://www.postgresql.org/docs/current/catalog-pg-namespace.html: stores namespaces. A namespace is the structure underlying SQL schemas: each namespace can have a separate collection of relations, types, etc. without name conflicts.
    return conn.query<RawConstraint>(`
        SELECT cn.contype                         AS constraint_type
             , cn.conname                         AS constraint_name
             , n.nspname                          AS table_schema
             , c.relname                          AS table_name
             , cn.conkey                          AS columns
             , pg_get_constraintdef(cn.oid, true) AS definition
        FROM pg_constraint cn
                 JOIN pg_class c ON c.oid = cn.conrelid
                 JOIN pg_namespace n ON n.oid = c.relnamespace
        WHERE cn.contype IN ('p', 'c')
          AND ${filterSchema('n.nspname', schema)}
        ORDER BY table_schema, table_name, constraint_name;`, [], 'getConstraints'
    ).catch(handleError(`Failed to get constraints${schema ? ` for schema '${schema}'` : ''}`, [], ignoreErrors, logger))
}

type RawIndex = {
    index_name: string
    table_schema: string
    table_name: string
    columns: number[]
    definition: string
    is_unique: boolean
}

async function getIndexes(conn: Conn, schema: PostgresSchemaName | undefined, ignoreErrors: boolean, logger: Logger): Promise<RawIndex[]> {
    // https://www.postgresql.org/docs/current/catalog-pg-index.html: contains part of the information about indexes. The rest is mostly in pg_class.
    // https://www.postgresql.org/docs/current/catalog-pg-class.html: catalogs tables and most everything else that has columns or is otherwise similar to a table. This includes indexes (but see also pg_index), sequences (but see also pg_sequence), views, materialized views, composite types, and TOAST tables; see relkind.
    // https://www.postgresql.org/docs/current/catalog-pg-namespace.html: stores namespaces. A namespace is the structure underlying SQL schemas: each namespace can have a separate collection of relations, types, etc. without name conflicts.
    return conn.query<RawIndex>(`
        SELECT ic.relname                             AS index_name
             , tn.nspname                             AS table_schema
             , tc.relname                             AS table_name
             , i.indkey::integer[]                    AS columns
             , pg_get_indexdef(i.indexrelid, 0, true) AS definition
             , i.indisunique                          AS is_unique
        FROM pg_index i
                 JOIN pg_class ic ON ic.oid = i.indexrelid
                 JOIN pg_class tc ON tc.oid = i.indrelid
                 JOIN pg_namespace tn ON tn.oid = tc.relnamespace
        WHERE i.indisprimary = false
          AND ${filterSchema('tn.nspname', schema)}
        ORDER BY table_schema, table_name, index_name;`, [], 'getIndexes'
    ).then(rows => rows.map(row => ({
        ...row,
        definition: row.definition.indexOf(' USING ') > 0 ? row.definition.split(' USING ')[1].trim() : row.definition
    }))).catch(handleError(`Failed to get indexes${schema ? ` for schema '${schema}'` : ''}`, [], ignoreErrors, logger))
}

type RawComment = {
    table_schema: string
    table_name: string
    column_name: string | null
    comment: string
}

async function getComments(conn: Conn, schema: PostgresSchemaName | undefined, ignoreErrors: boolean, logger: Logger): Promise<RawComment[]> {
    // https://www.postgresql.org/docs/current/catalog-pg-description.html: stores optional descriptions (comments) for each database object.
    // https://www.postgresql.org/docs/current/catalog-pg-class.html: catalogs tables and most everything else that has columns or is otherwise similar to a table. This includes indexes (but see also pg_index), sequences (but see also pg_sequence), views, materialized views, composite types, and TOAST tables; see relkind.
    // https://www.postgresql.org/docs/current/catalog-pg-namespace.html: stores namespaces. A namespace is the structure underlying SQL schemas: each namespace can have a separate collection of relations, types, etc. without name conflicts.
    // https://www.postgresql.org/docs/current/catalog-pg-attribute.html: stores information about table columns. There will be exactly one row for every column in every table in the database.
    return conn.query<RawComment>(`
        SELECT n.nspname     AS table_schema
             , c.relname     AS table_name
             , a.attname     AS column_name
             , d.description AS comment
        FROM pg_description d
                 JOIN pg_class c ON c.oid = d.objoid
                 JOIN pg_namespace n ON n.oid = c.relnamespace
                 LEFT OUTER JOIN pg_attribute a ON a.attrelid = c.oid AND a.attnum = d.objsubid
        WHERE c.relkind IN ('r', 'v', 'm')
          AND ${filterSchema('n.nspname', schema)}
        ORDER BY table_schema, table_name, column_name;`, [], 'getComments'
    ).catch(handleError(`Failed to get comments${schema ? ` for schema '${schema}'` : ''}`, [], ignoreErrors, logger))
}

type RawRelation = {
    constraint_name: string
    table_schema: string
    table_name: string
    columns: number[]
    target_schema: string
    target_table: string
    target_columns: number[]
}

async function getRelations(conn: Conn, schema: PostgresSchemaName | undefined, ignoreErrors: boolean, logger: Logger): Promise<RawRelation[]> {
    // https://www.postgresql.org/docs/current/catalog-pg-constraint.html: stores check, primary key, unique, foreign key, and exclusion constraints on tables. Not-null constraints are represented in the pg_attribute catalog, not here.
    // https://www.postgresql.org/docs/current/catalog-pg-class.html: catalogs tables and most everything else that has columns or is otherwise similar to a table. This includes indexes (but see also pg_index), sequences (but see also pg_sequence), views, materialized views, composite types, and TOAST tables; see relkind.
    // https://www.postgresql.org/docs/current/catalog-pg-namespace.html: stores namespaces. A namespace is the structure underlying SQL schemas: each namespace can have a separate collection of relations, types, etc. without name conflicts.
    return conn.query<RawRelation>(`
        SELECT cn.conname AS constraint_name
             , n.nspname  AS table_schema
             , c.relname  AS table_name
             , cn.conkey  AS columns
             , tn.nspname AS target_schema
             , tc.relname AS target_table
             , cn.confkey AS target_columns
        FROM pg_constraint cn
                 JOIN pg_class c ON c.oid = cn.conrelid
                 JOIN pg_namespace n ON n.oid = c.relnamespace
                 JOIN pg_class tc ON tc.oid = cn.confrelid
                 JOIN pg_namespace tn ON tn.oid = tc.relnamespace
        WHERE cn.contype IN ('f')
          AND ${filterSchema('n.nspname', schema)}
        ORDER BY table_schema, table_name, constraint_name;`, [], 'getRelations'
    ).catch(handleError(`Failed to get relations${schema ? ` for schema '${schema}'` : ''}`, [], ignoreErrors, logger))
}

type RawType = {
    type_schema: string
    type_name: string
    internal_name: string
    type_kind: 'b' | 'c' | 'd' | 'e' | 'p' | 'r' | 'm' // b: base, c: composite, d: domain, e: enum, p: pseudo-type, r: range, m: multirange
    enum_values: string[]
    type_comment: string | null
}

async function getTypes(conn: Conn, schema: PostgresSchemaName | undefined, ignoreErrors: boolean, logger: Logger): Promise<RawType[]> {
    // https://www.postgresql.org/docs/current/catalog-pg-enum.html: values and labels for each enum type
    // https://www.postgresql.org/docs/current/catalog-pg-type.html: stores data types
    // https://www.postgresql.org/docs/current/catalog-pg-class.html: catalogs tables and most everything else that has columns or is otherwise similar to a table. This includes indexes (but see also pg_index), sequences (but see also pg_sequence), views, materialized views, composite types, and TOAST tables; see relkind.
    // https://www.postgresql.org/docs/current/catalog-pg-namespace.html: stores namespaces. A namespace is the structure underlying SQL schemas: each namespace can have a separate collection of relations, types, etc. without name conflicts.
    return conn.query<RawType>(`
        SELECT n.nspname                                AS type_schema,
               format_type(t.oid, NULL)                 AS type_name,
               t.typname                                AS internal_name,
               t.typtype                                AS type_kind,
               array(SELECT enumlabel
                     FROM pg_enum
                     WHERE enumtypid = t.oid
                     ORDER BY enumsortorder)::varchar[] AS enum_values,
               obj_description(t.oid, 'pg_type')        AS type_comment
        FROM pg_type t
                 JOIN pg_namespace n ON n.oid = t.typnamespace
        WHERE (t.typrelid = 0 OR (SELECT c.relkind = 'c' FROM pg_class c WHERE c.oid = t.typrelid))
          AND NOT EXISTS(SELECT 1 FROM pg_type WHERE oid = t.typelem AND typarray = t.oid)
          AND ${filterSchema('n.nspname', schema)}
        ORDER BY type_schema, type_name;`, [], 'getTypes'
    ).catch(handleError(`Failed to get types${schema ? ` for schema '${schema}'` : ''}`, [], ignoreErrors, logger))
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

function filterSchema(field: string, schema: PostgresSchemaName | undefined) {
    return `${field} ${schema ? `= '${schema}'` : `NOT IN ('information_schema', 'pg_catalog')`}`
}
