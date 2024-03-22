import {parse} from "postgres-array";
import {groupBy, mapEntriesAsync, mapValuesAsync, removeEmpty, removeUndefined, zip} from "@azimutt/utils";
import {
    Attribute,
    AttributeName,
    AttributeValue,
    ConnectorSchemaOpts,
    connectorSchemaOptsDefaults,
    Database,
    Entity,
    EntityId,
    EntityName,
    formatEntityRef,
    isPolymorphic,
    parseEntityRef,
    SchemaName,
    schemaToAttributes,
    ValueSchema,
    valuesToSchema
} from "@azimutt/database-model";
import {Conn} from "./common";
import {buildSqlColumn, buildSqlTable} from "./helpers";

export const getSchema = (opts: ConnectorSchemaOpts) => async (conn: Conn): Promise<Database> => {
    const blockSize: number = await getBlockSize(opts)(conn)
    const tables: RawTable[] = await getTables(opts)(conn)
    const columns: Record<EntityId, RawColumn[]> = await getColumns(opts)(conn).then(cols => groupBy(cols, toEntityId))
    const columnSchemas: Record<EntityId, Record<AttributeName, ValueSchema>> = opts.inferJsonAttributes ? await mapEntriesAsync(columns, (entityId, tableCols) => {
        const {schema, entity} = parseEntityRef(entityId)
        const jsonCols = Object.fromEntries(tableCols.filter(c => c.column_type === 'jsonb').map(c => [c.column_name, c.column_name]))
        return mapValuesAsync(jsonCols, c => inferColumnSchema(schema, entity, c, opts)(conn))
    }) : {}
    const columnPolys: Record<EntityId, Record<AttributeName, string[]>> = opts.inferPolymorphicRelations ? await mapEntriesAsync(columns, (entityId, tableCols) => {
        const {schema, entity} = parseEntityRef(entityId)
        const colNames = tableCols.map(c => c.column_name)
        const polyCols = Object.fromEntries(tableCols.filter(c => isPolymorphic(c.column_name, colNames)).map(c => [c.column_name, c.column_name]))
        return mapValuesAsync(polyCols, c => getColumnDistinctValues(schema, entity, c, opts)(conn))
    }) : {}
    return Promise.resolve({
        entities: tables.map(table => {
            const id = toEntityId(table)
            return buildEntity(blockSize, table, columns[id] || [], columnSchemas[id] || {}, columnPolys[id] || {})
        }),
        relations: [],
        types: [],
    })
}

/*export const getSchema = ({logger, schema, sampleSize, inferRelations, ignoreErrors}: PostgresSchemaOpts) => async (conn: Conn): Promise<Database> => {
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
}*/

// 👇️ Private functions, some are exported only for tests
// If you use them, beware of breaking changes!

function toEntityId<T extends { table_schema: string, table_name: string }>(value: T): EntityId {
    return formatEntityRef({schema: value.table_schema, entity: value.table_name})
}

export const getBlockSize = ({logger, schema, entity, ignoreErrors}: ConnectorSchemaOpts) => async (conn: Conn): Promise<number> => {
    return conn.query<{block_size: number}>(`SHOW block_size;`, [], 'getBlockSize')
        .then(res => res[0]?.block_size || 8192)
        .catch(handleError(`Failed to get block size`, 0, {logger, ignoreErrors}))
}

export type RawTable = {
    table_id: number
    table_owner: string
    table_schema: string
    table_name: string
    table_kind: 'r' | 'v' | 'm' // r: table, v: view, m: materialized view
    table_definition: string | null
    table_partition: string | null
    table_comment: string | null
    attributes_count: number
    checks_count: number
    rows: number
    rows_dead: number
    blocks: number
    idx_blocks: number
    seq_scan: number
    seq_scan_reads: number
    seq_scan_last: Date | null
    idx_scan: number
    idx_scan_reads: number
    idx_scan_last: Date | null
    analyze_count: number
    analyze_last: Date | null
    autoanalyze_count: number
    autoanalyze_last: Date | null
    changes_since_analyze: number
    vacuum_count: number
    vacuum_last: Date | null
    autovacuum_count: number
    autovacuum_last: Date | null
    changes_since_vacuum: number
    toast_schema: string | null
    toast_name: string | null
    toast_blocks: number | null
    toast_idx_blocks: number | null
}

export const getTables = ({logger, schema, entity, ignoreErrors}: ConnectorSchemaOpts) => async (conn: Conn): Promise<RawTable[]> => {
    // https://www.postgresql.org/docs/current/catalog-pg-class.html: catalogs tables and most everything else that has columns or is otherwise similar to a table. This includes indexes (but see also pg_index), sequences (but see also pg_sequence), views, materialized views, composite types, and TOAST tables; see relkind.
    // https://www.postgresql.org/docs/current/catalog-pg-namespace.html: stores namespaces. A namespace is the structure underlying SQL schemas: each namespace can have a separate collection of relations, types, etc. without name conflicts.
    // https://www.postgresql.org/docs/current/catalog-pg-authid.html: store users
    // https://www.postgresql.org/docs/current/catalog-pg-description.html: stores optional descriptions (comments) for each database object.
    // https://www.postgresql.org/docs/current/functions-info.html#FUNCTIONS-INFO-CATALOG
    // https://www.postgresql.org/docs/current/monitoring-stats.html#MONITORING-PG-STAT-ALL-TABLES-VIEW: stats on tables
    // https://www.postgresql.org/docs/current/monitoring-stats.html#MONITORING-PG-STATIO-ALL-TABLES-VIEW: stats on table blocks
    // `c.relkind IN ('r', 'v', 'm')`: get only tables, view and materialized views
    return conn.query<RawTable>(`
        SELECT c.oid                       AS table_id
             , u.rolname                   AS table_owner
             , n.nspname                   AS table_schema
             , c.relname                   AS table_name
             , c.relkind                   AS table_kind
             , pg_get_viewdef(c.oid, true) AS table_definition
             , pg_get_partkeydef(c.oid)    AS table_partition
             , d.description               AS table_comment
             , c.relnatts                  AS attributes_count
             , c.relchecks                 AS checks_count
             , s.n_live_tup                AS rows
             , s.n_dead_tup                AS rows_dead
             , io.heap_blks_read           AS blocks
             , io.idx_blks_read            AS idx_blocks
             , s.seq_scan
             , s.seq_tup_read              AS seq_scan_reads
             , s.last_seq_scan             AS seq_scan_last
             , s.idx_scan
             , s.idx_tup_fetch             AS idx_scan_reads
             , s.last_idx_scan             AS idx_scan_last
             , s.analyze_count
             , s.last_analyze              AS analyze_last
             , s.autoanalyze_count
             , s.last_autoanalyze          AS autoanalyze_last
             , s.n_mod_since_analyze       AS changes_since_analyze
             , s.vacuum_count
             , s.last_vacuum               AS vacuum_last
             , s.autovacuum_count
             , s.last_autovacuum           AS autovacuum_last
             , s.n_ins_since_vacuum        AS changes_since_vacuum
             , tn.nspname                  AS toast_schema
             , tc.relname                  AS toast_name
             , io.toast_blks_read          AS toast_blocks
             , io.tidx_blks_read           AS toast_idx_blocks
        FROM pg_class c
                 JOIN pg_namespace n ON n.oid = c.relnamespace
                 JOIN pg_authid u ON u.oid = c.relowner
                 LEFT JOIN pg_description d ON d.objoid = c.oid AND d.objsubid = 0
                 LEFT JOIN pg_class tc ON tc.oid = c.reltoastrelid
                 LEFT JOIN pg_namespace tn ON tn.oid = tc.relnamespace
                 LEFT JOIN pg_stat_all_tables s ON s.relid = c.oid
                 LEFT JOIN pg_statio_all_tables io ON io.relid = c.oid
        WHERE ${scopeFilter('n.nspname', schema, 'c.relname', entity)}
          AND c.relkind IN ('r', 'v', 'm')
        ORDER BY table_schema, table_name;`, [], 'getTables'
    ).catch(handleError(`Failed to get tables`, [], {logger, ignoreErrors}))
}

function buildEntity(blockSize: number, table: RawTable, columns: RawColumn[], jsonColumns: Record<AttributeName, ValueSchema>, polyColumns: Record<AttributeName, string[]>): Entity {
    return removeEmpty({
        name: table.table_name,
        kind: table.table_kind === 'v' ? 'view' : table.table_kind === 'm' ? 'materialized view' : undefined,
        def: table.table_definition || undefined,
        attrs: columns.sort((a, b) => a.column_index - b.column_index).map(c => buildAttribute(c, jsonColumns[c.column_name], polyColumns[c.column_name])),
        pk: undefined, // TODO
        indexes: undefined, // TODO
        checks: undefined, // TODO
        doc: table.table_comment || undefined,
        stats: removeUndefined({
            rows: table.rows,
            size: table.blocks * blockSize,
            sizeIdx: table.idx_blocks * blockSize,
            sizeToast: table.toast_blocks ? table.toast_blocks * blockSize : undefined,
            sizeToastIdx: table.toast_idx_blocks ? table.toast_idx_blocks * blockSize : undefined,
            seq_scan: table.seq_scan,
            idx_scan: table.idx_scan,
        }),
        extra: undefined
    } as Entity)
}

// https://www.postgresql.org/docs/current/catalog-pg-type.html#CATALOG-TYPCATEGORY-TABLE
export type TypeCategory = 'A' | 'B' | 'C' | 'D' | 'E' | 'G' | 'I' | 'N' | 'P' | 'R' | 'S' | 'T' | 'U' | 'V' | 'X' | 'Z' // A: array, B: bool, C: composite, D: date, E: enum, G: geo, I: inet, N: numeric, P: pseudo, R: range, S: string, T: timespan, U: user-defined, V: bit, X: unknown, Z: internal
export type RawColumn = {
    table_id: number
    table_owner: string
    table_schema: string
    table_name: string
    table_kind: 'r' | 'v' | 'm' // r: table, v: view, m: materialized view
    column_index: number
    column_name: string
    column_type: string
    column_type_name: string
    column_type_len: number
    column_type_cat: TypeCategory
    column_default: string | null
    column_nullable: boolean
    column_generated: boolean
    column_comment: string | null
    nulls: number | null // percentage of nulls (between 0 & 1)
    avg_len: number | null
    cardinality: number | null // if negative: negative of distinct values divided by the number of rows (% of uniqueness)
    common_vals: string | null
    common_freqs: number[] | null
    histogram: string | null
}

export const getColumns = ({logger, schema, entity, ignoreErrors}: ConnectorSchemaOpts) => async (conn: Conn): Promise<RawColumn[]> => {
    // https://www.postgresql.org/docs/current/catalog-pg-attribute.html: stores information about table columns. There will be exactly one row for every column in every table in the database.
    // https://www.postgresql.org/docs/current/catalog-pg-class.html: catalogs tables and most everything else that has columns or is otherwise similar to a table. This includes indexes (but see also pg_index), sequences (but see also pg_sequence), views, materialized views, composite types, and TOAST tables; see relkind.
    // https://www.postgresql.org/docs/current/catalog-pg-namespace.html: stores namespaces. A namespace is the structure underlying SQL schemas: each namespace can have a separate collection of relations, types, etc. without name conflicts.
    // https://www.postgresql.org/docs/current/catalog-pg-authid.html: store users
    // https://www.postgresql.org/docs/current/catalog-pg-type.html: stores information about data types
    // https://www.postgresql.org/docs/current/catalog-pg-attrdef.html: stores column default values.
    // https://www.postgresql.org/docs/current/view-pg-stats.html: column statistics
    // https://www.postgresql.org/docs/current/functions-info.html#FUNCTIONS-INFO-CATALOG
    // `c.relkind IN ('r', 'v', 'm')`: get only tables, view and materialized views
    // `a.attnum > 0`: avoid system columns
    // `a.atttypid != 0`: avoid deleted columns
    return conn.query<RawColumn>(`
        SELECT c.oid                                AS table_id
             , u.rolname                            AS table_owner
             , n.nspname                            AS table_schema
             , c.relname                            AS table_name
             , c.relkind                            AS table_kind
             , a.attnum                             AS column_index
             , a.attname                            AS column_name
             , format_type(a.atttypid, a.atttypmod) AS column_type
             , t.typname                            AS column_type_name
             , t.typlen                             AS column_type_len
             , t.typcategory                        AS column_type_cat
             , pg_get_expr(ad.adbin, ad.adrelid)    AS column_default
             , NOT a.attnotnull                     AS column_nullable
             , a.attgenerated = 's'                 AS column_generated
             , d.description                        AS column_comment
             , null_frac                            AS nulls
             , avg_width                            AS avg_len
             , n_distinct                           AS cardinality
             , most_common_vals                     AS common_vals
             , most_common_freqs                    AS common_freqs
             , histogram_bounds                     AS histogram
        FROM pg_attribute a
                 JOIN pg_class c ON c.oid = a.attrelid
                 JOIN pg_namespace n ON n.oid = c.relnamespace
                 JOIN pg_authid u ON u.oid = c.relowner
                 JOIN pg_type t ON t.oid = a.atttypid
                 LEFT JOIN pg_attrdef ad ON ad.adrelid = c.oid AND ad.adnum = a.attnum
                 LEFT JOIN pg_description d ON d.objoid = c.oid AND d.objsubid = a.attnum
                 LEFT JOIN pg_stats s ON s.schemaname = n.nspname AND s.tablename = c.relname AND s.attname = a.attname
        WHERE ${scopeFilter('n.nspname', schema, 'c.relname', entity)}
          AND c.relkind IN ('r', 'v', 'm')
          AND a.attnum > 0
          AND a.atttypid != 0
        ORDER BY table_schema, table_name, column_index;`, [], 'getColumns'
    ).catch(handleError(`Failed to get columns`, [], {logger, ignoreErrors}))
}

function buildAttribute(c: RawColumn, schema: ValueSchema | undefined, values: string[] | undefined): Attribute {
    return removeEmpty({
        name: c.column_name,
        type: c.column_type,
        nullable: c.column_nullable || undefined,
        generated: c.column_generated || undefined,
        default: c.column_default || undefined,
        values: values,
        attrs: schema ? schemaToAttributes(schema, 0) : undefined,
        doc: c.column_comment || undefined,
        stats: removeUndefined({
            nulls: c.nulls || undefined,
            avgBytes: c.avg_len || undefined,
            cardinality: c.cardinality && c.cardinality > 0 ? c.cardinality : undefined,
            commonValues: c.common_vals && c.common_freqs ? zip(parseValues(c.common_vals, c.column_type_cat, c.column_type_name), c.common_freqs).map(([value, freq]) => ({value, freq})) : undefined,
            histogram: c.histogram ? parseValues(c.histogram, c.column_type_cat, c.column_type_name) : undefined
        }),
        extra: undefined,
    } as Attribute)
}

function parseValues(anyArray: string, type_cat: TypeCategory, type_name: string): AttributeValue[] {
    switch (type_cat) {
        case "A": return parse(anyArray, v => v) // array, keep string (ex: int2vector, oidvector, _bool, _char, _int4, _json...)
        case "B": return parse(anyArray, v => v === 'true') // boolean (ex: bool)
        case "C": return parse(anyArray, v => v) // composite, keep string (ex: pg_type, pg_class...)
        case "D": return parse(anyArray, v => new Date(v)) // date, keep string (ex: timestamp, date, time, timestamptz...)
        case "E": return parse(anyArray, v => v) // enum, keep string
        case "G": return parse(anyArray, v => v) // geometric, keep string (ex: point, line, polygon, path...)
        case "I": return parse(anyArray, v => v) // network, keep string (ex: inet, cidr)
        case "N": return parse(anyArray, v => Number(v)) // numeric (ex: int2, int4, int8, oid, float4, float8, numeric, money...)
        case "P": return parse(anyArray, v => v) // pseudo, keep string (ex: record, void, any, anyarray, trigger...)
        case "R": return parse(anyArray, v => v) // range, keep string (ex: int4range, numrange, tsrange, daterange...)
        case "S": return parse(anyArray, v => v) // string (ex: varchar, text, name, citext...)
        case "T": return parse(anyArray, v => v) // timespan, keep string (ex: interval)
        case "U": // user-defined, keep string (ex: uuid, json, jsonb, xml, bytea, cid, tsvector, macaddr...)
            if (type_name === 'json' || type_name === 'jsonb') {
                try {
                    return parse(anyArray, v => JSON.parse(v))
                } catch (e) {
                    return parse(anyArray, v => v)
                }
            } else {
                return parse(anyArray, v => v)
            }
        case "V": return parse(anyArray, v => v) // bit-string, keep string (ex: bit, varbit)
        case "X": return parse(anyArray, v => v) // unknown, keep string (ex: unknown)
        case "Z": return parse(anyArray, v => v) // internal, keep string (ex: char, pg_node_tree...)
    }
}

const inferColumnSchema = (schema: SchemaName | undefined, table: EntityName, column: AttributeName, opts: ConnectorSchemaOpts) => async (conn: Conn): Promise<ValueSchema> => {
    const sqlTable = buildSqlTable(schema, table)
    const sqlColumn = buildSqlColumn(column)
    const sampleSize = opts.sampleSize || connectorSchemaOptsDefaults.sampleSize
    return conn.query(`SELECT ${sqlColumn} FROM ${sqlTable} WHERE ${sqlColumn} IS NOT NULL LIMIT ${sampleSize};`, [], 'inferColumnSchema')
        .then(rows => valuesToSchema(rows.map(row => row[column])))
        .catch(handleError(`Failed to infer schema for column '${schema ? schema + '.' : ''}${table}(${column})'`, valuesToSchema([]), opts))
}

const getColumnDistinctValues = (schema: SchemaName | undefined, table: EntityName, column: AttributeName, opts: ConnectorSchemaOpts) => async (conn: Conn): Promise<string[]> => {
    const sqlTable = buildSqlTable(schema, table)
    const sqlColumn = buildSqlColumn(column)
    return conn.query<{value: string}>(`SELECT DISTINCT ${sqlColumn} as value FROM ${sqlTable} WHERE ${sqlColumn} IS NOT NULL ORDER BY value LIMIT 30;`, [], 'getColumnDistinctValues')
        .then(rows => rows.map(v => v.value?.toString()))
        .catch(handleError(`Failed to get distinct values for column '${schema ? schema + '.' : ''}${table}(${column})'`, [], opts))
}

/*type RawConstraint = {
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
    // https://www.postgresql.org/docs/current/functions-info.html#FUNCTIONS-INFO-CATALOG
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
}*/

/*type RawIndex = {
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
}*/

/*type RawRelation = {
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
}*/

/*type RawType = {
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
}*/

// getTriggers: pg_get_triggerdef
// getFunctions / getProcedures: pg_get_functiondef, pg_get_function_arguments, pg_get_function_identity_arguments, pg_get_function_result (https://www.postgresql.org/docs/current/functions-info.html#FUNCTIONS-INFO-CATALOG)

function handleError<T>(msg: string, onError: T, {logger, ignoreErrors}: ConnectorSchemaOpts) {
    return (err: any): Promise<T> => {
        if (ignoreErrors) {
            logger.warn(`${msg}. Ignoring...`)
            return Promise.resolve(onError)
        } else {
            return Promise.reject(err)
        }
    }
}

function scopeFilter(schemaField: string, schemaScope: SchemaName | undefined, entityField: string, entityScope: EntityName | undefined) {
    const schemaFilter = schemaScope ? `${schemaField} ${schemaScope.includes('%') ? 'LIKE' : '='} '${schemaScope}'` : `${schemaField} NOT IN ('information_schema', 'pg_catalog')`
    const entityFilter = entityScope ? ` AND ${entityField} ${entityScope.includes('%') ? 'LIKE' : '='} '${entityScope}'` : ''
    return schemaFilter + entityFilter
}
