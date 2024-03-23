import {parse} from "postgres-array";
import {groupBy, mapEntriesAsync, mapValues, mapValuesAsync, removeEmpty, removeUndefined, zip} from "@azimutt/utils";
import {
    Attribute,
    AttributeName,
    AttributeValue,
    Check,
    ConnectorSchemaOpts,
    connectorSchemaOptsDefaults,
    Database,
    Entity,
    EntityId,
    EntityName,
    formatEntityRef,
    Index,
    isPolymorphic,
    parseEntityRef,
    PrimaryKey,
    Relation,
    SchemaName,
    schemaToAttributes,
    Type,
    ValueSchema,
    valuesToSchema
} from "@azimutt/database-model";
import {Conn} from "./common";
import {buildSqlColumn, buildSqlTable} from "./helpers";

export const getSchema = (opts: ConnectorSchemaOpts) => async (conn: Conn): Promise<Database> => {
    const blockSize: number = await getBlockSize(opts)(conn)
    const database: RawDatabase = await getDatabase(opts)(conn)
    const tables: RawTable[] = await getTables(opts)(conn)
    const columns: Record<EntityId, RawColumn[]> = await getColumns(opts)(conn).then(cols => groupBy(cols, toEntityId))
    const columnsByIndex: Record<EntityId, { [i: number]: string }> = mapValues(columns, cols => cols.reduce((acc, col) => ({...acc, [col.column_index]: col.column_name}), {}))
    const constraints: Record<EntityId, RawConstraint[]> = await getConstraints(opts)(conn).then(cols => groupBy(cols, toEntityId))
    const indexes: Record<EntityId, RawIndex[]> = await getIndexes(opts)(conn).then(cols => groupBy(cols, toEntityId))
    const relations: RawRelation[] = await getRelations(opts)(conn)
    const types: RawType[] = await getTypes(opts)(conn)
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
    return removeUndefined({
        entities: tables.map(table => {
            const id = toEntityId(table)
            return buildEntity(blockSize, table, columns[id] || [], columnsByIndex[id] || {}, constraints[id] || [], indexes[id] || [], columnSchemas[id] || {}, columnPolys[id] || {})
        }),
        relations: relations.map(r => buildRelation(r, columnsByIndex)),
        types: types.map(buildType),
        doc: undefined,
        stats: undefined,
        extra: undefined,
    })
}

// 👇️ Private functions, some are exported only for tests
// If you use them, beware of breaking changes!

function toEntityId<T extends { table_schema: string, table_name: string }>(value: T): EntityId {
    return formatEntityRef({schema: value.table_schema, entity: value.table_name})
}

export type RawDatabase = {
    version: string
    address: string
    port: number
    user: string
    database: string
    schema: string
    commits: number
    rollbacks: number
    blks_read: number
    blks_hit: number
    tup_returned: number
    tup_inserted: number
    tup_updated: number
    tup_deleted: number
}

export const getDatabase = (opts: ConnectorSchemaOpts) => async (conn: Conn): Promise<RawDatabase> => {
    const onError: RawDatabase = {version: '', address: '', port: 0, user: '', database: '', schema: '', commits: 0, rollbacks: 0, blks_read: 0, blks_hit: 0, tup_returned: 0, tup_inserted: 0, tup_updated: 0, tup_deleted: 0}
    return conn.query<RawDatabase>(`
        SELECT version()
             , inet_server_addr() AS address
             , inet_server_port() AS port
             , user
             , datname            AS database
             , current_schema()   AS schema
             , xact_commit        AS commits
             , xact_rollback      AS rollbacks
             , blks_read
             , blks_hit
             , tup_returned
             , tup_inserted
             , tup_updated
             , tup_deleted
        FROM pg_stat_database
        WHERE datname = current_database();`, [], 'getDatabaseStats')
        .then(res => res[0] || onError)
        .catch(handleError(`Failed to get database info`, onError, opts))
}

export const getBlockSize = (opts: ConnectorSchemaOpts) => async (conn: Conn): Promise<number> => {
    return conn.query<{block_size: number}>(`SHOW block_size;`, [], 'getBlockSize')
        .then(res => res[0]?.block_size || 8192)
        .catch(handleError(`Failed to get block size`, 0, opts))
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

export const getTables = ({schema, entity, logger, ignoreErrors}: ConnectorSchemaOpts) => async (conn: Conn): Promise<RawTable[]> => {
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

function buildEntity(blockSize: number, table: RawTable, columns: RawColumn[], columnsByIndex: { [i: number]: string }, constraints: RawConstraint[], indexes: RawIndex[], jsonColumns: Record<AttributeName, ValueSchema>, polyColumns: Record<AttributeName, string[]>): Entity {
    return removeEmpty({
        name: table.table_name,
        kind: table.table_kind === 'v' ? 'view' : table.table_kind === 'm' ? 'materialized view' : undefined,
        def: table.table_definition || undefined,
        attrs: columns.slice(0).sort((a, b) => a.column_index - b.column_index).map(c => buildAttribute(c, jsonColumns[c.column_name], polyColumns[c.column_name])),
        pk: constraints.filter(c => c.constraint_type === 'p').map(c => buildPrimaryKey(c, columnsByIndex))[0] || undefined,
        indexes: indexes.map(i => buildIndex(blockSize, i, columnsByIndex)),
        checks: constraints.filter(c => c.constraint_type === 'c').map(c => buildCheck(c, columnsByIndex)),
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
    column_type_cat: RawTypeCategory
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

export const getColumns = ({schema, entity, logger, ignoreErrors}: ConnectorSchemaOpts) => async (conn: Conn): Promise<RawColumn[]> => {
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

function parseValues(anyArray: string, type_cat: RawTypeCategory, type_name: string): AttributeValue[] {
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

type RawConstraint = {
    table_schema: string
    table_name: string
    constraint_name: string
    constraint_type: 'p' | 'c' // p: primary key, c: check
    columns: number[]
    deferrable: boolean
    definition: string
    constraint_comment: string | null
}

export const getConstraints = ({schema, entity, logger, ignoreErrors}: ConnectorSchemaOpts) => async (conn: Conn): Promise<RawConstraint[]> => {
    // https://www.postgresql.org/docs/current/catalog-pg-constraint.html: stores check, primary key, unique, foreign key, and exclusion constraints on tables. Not-null constraints are represented in the pg_attribute catalog, not here.
    // https://www.postgresql.org/docs/current/catalog-pg-class.html: catalogs tables and most everything else that has columns or is otherwise similar to a table. This includes indexes (but see also pg_index), sequences (but see also pg_sequence), views, materialized views, composite types, and TOAST tables; see relkind.
    // https://www.postgresql.org/docs/current/catalog-pg-namespace.html: stores namespaces. A namespace is the structure underlying SQL schemas: each namespace can have a separate collection of relations, types, etc. without name conflicts.
    // https://www.postgresql.org/docs/current/catalog-pg-description.html: stores optional descriptions (comments) for each database object.
    // https://www.postgresql.org/docs/current/functions-info.html#FUNCTIONS-INFO-CATALOG
    // `c.contype IN ('p', 'c')`: get only primary key and check constraints
    return conn.query<RawConstraint>(`
        SELECT cn.nspname                        AS table_schema
             , cl.relname                        AS table_name
             , c.conname                         AS constraint_name
             , c.contype                         AS constraint_type
             , c.conkey                          AS columns
             , c.condeferrable                   AS deferrable
             , pg_get_constraintdef(c.oid, true) AS definition
             , d.description                     AS constraint_comment
        FROM pg_constraint c
                 JOIN pg_class cl ON cl.oid = c.conrelid
                 JOIN pg_namespace cn ON cn.oid = cl.relnamespace
                 LEFT JOIN pg_description d ON d.objoid = c.oid
        WHERE ${scopeFilter('cn.nspname', schema, 'cl.relname', entity)}
          AND c.contype IN ('p', 'c');`, [], 'getConstraints'
    ).catch(handleError(`Failed to get constraints`, [], {logger, ignoreErrors}))
}

function buildPrimaryKey(c: RawConstraint, columns: { [i: number]: string }): PrimaryKey {
    return {
        name: c.constraint_name,
        attrs: c.columns.map(i => [columns[i] || 'unknown']),
        doc: c.constraint_comment || undefined,
        stats: undefined,
        extra: undefined
    }
}

function buildCheck(c: RawConstraint, columns: { [i: number]: string }): Check {
    return {
        name: c.constraint_name,
        attrs: c.columns.map(i => [columns[i] || 'unknown']),
        predicate: c.definition,
        doc: c.constraint_comment || undefined,
        stats: undefined,
        extra: undefined
    }
}

type RawIndex = {
    table_schema: string
    table_name: string
    index_name: string
    columns: number[]
    is_unique: boolean
    partial: string | null
    definition: string
    rows: number
    blocks: number
    idx_scan: number
    idx_scan_reads: number
    idx_scan_last: Date | null
    index_comment: string | null
}

export const getIndexes = ({schema, entity, logger, ignoreErrors}: ConnectorSchemaOpts) => async (conn: Conn): Promise<RawIndex[]> => {
    // https://www.postgresql.org/docs/current/catalog-pg-index.html: contains part of the information about indexes. The rest is mostly in pg_class.
    // https://www.postgresql.org/docs/current/catalog-pg-class.html: catalogs tables and most everything else that has columns or is otherwise similar to a table. This includes indexes (but see also pg_index), sequences (but see also pg_sequence), views, materialized views, composite types, and TOAST tables; see relkind.
    // https://www.postgresql.org/docs/current/catalog-pg-description.html: stores optional descriptions (comments) for each database object.
    // https://www.postgresql.org/docs/current/monitoring-stats.html#MONITORING-PG-STAT-ALL-INDEXES-VIEW: stats on indexes
    // https://www.postgresql.org/docs/current/functions-info.html#FUNCTIONS-INFO-CATALOG
    // `i.indisprimary = false`: primary keys are fetch an other way
    return conn.query<RawIndex>(`
        SELECT s.schemaname                           AS table_schema
             , s.relname                              AS table_name
             , s.indexrelname                         AS index_name
             , i.indkey::integer[]                    AS columns
             , i.indisunique                          AS is_unique
             , pg_get_expr(i.indpred, i.indrelid)     AS partial
             , pg_get_indexdef(i.indexrelid, 0, true) AS definition
             , c.reltuples                            AS rows
             , c.relpages                             AS blocks
             , s.idx_scan                             AS idx_scan
             , s.idx_tup_fetch                        AS idx_scan_reads
             , s.last_idx_scan                        AS idx_scan_last
             , d.description                          AS index_comment
        FROM pg_index i
                 JOIN pg_class c ON c.oid = i.indexrelid
                 JOIN pg_stat_all_indexes s ON s.indexrelid = i.indexrelid
                 LEFT JOIN pg_description d ON d.objoid = i.indexrelid
        WHERE ${scopeFilter('s.schemaname', schema, 's.relname', entity)}
          AND i.indisprimary = false
        ORDER BY table_schema, table_name, index_name;`, [], 'getIndexes'
    ).then(rows => rows.map(row => ({
        ...row,
        definition: row.definition.indexOf(' USING ') > 0 ? row.definition.split(' USING ')[1].trim() : row.definition
    }))).catch(handleError(`Failed to get indexes`, [], {logger, ignoreErrors}))
}

function buildIndex(blockSize: number, index: RawIndex, columns: { [i: number]: string }): Index {
    return removeUndefined({
        name: index.index_name,
        attrs: index.columns.map(i => [columns[i] || 'unknown']), // TODO: handle indexes on nested json columns
        unique: index.is_unique || undefined,
        partial: index.partial !== null || undefined,
        definition: index.definition,
        doc: index.index_comment,
        stats: {
            size: index.blocks * blockSize,
            scans: index.idx_scan,
        },
        extra: undefined
    } as Index)
}

type RawRelationAction = 'a' | 'r' | 'c' | 'n' | 'd' // a = no action, r = restrict, c = cascade, n = set null, d = set default
type RawRelationMatch = 'f' | 'p' | 's' // f = full, p = partial, s = simple
type RawRelation = {
    constraint_name: string
    table_schema: string
    table_name: string
    table_columns: number[]
    target_schema: string
    target_table: string
    target_columns: number[]
    is_deferrable: boolean
    on_update: RawRelationAction
    on_delete: RawRelationAction
    matching: RawRelationMatch
    definition: string
    relation_comment: string | null
}

export const getRelations = ({schema, entity, logger, ignoreErrors}: ConnectorSchemaOpts) => async (conn: Conn): Promise<RawRelation[]> => {
    // https://www.postgresql.org/docs/current/catalog-pg-constraint.html: stores check, primary key, unique, foreign key, and exclusion constraints on tables. Not-null constraints are represented in the pg_attribute catalog, not here.
    // https://www.postgresql.org/docs/current/catalog-pg-class.html: catalogs tables and most everything else that has columns or is otherwise similar to a table. This includes indexes (but see also pg_index), sequences (but see also pg_sequence), views, materialized views, composite types, and TOAST tables; see relkind.
    // https://www.postgresql.org/docs/current/catalog-pg-namespace.html: stores namespaces. A namespace is the structure underlying SQL schemas: each namespace can have a separate collection of relations, types, etc. without name conflicts.
    return conn.query<RawRelation>(`
        SELECT c.conname                         AS constraint_name
             , cn.nspname                        AS table_schema
             , cl.relname                        AS table_name
             , c.conkey                          AS table_columns
             , tn.nspname                        AS target_schema
             , tc.relname                        AS target_table
             , c.confkey                         AS target_columns
             , c.condeferrable                   AS is_deferrable
             , c.confupdtype                     AS on_update
             , c.confdeltype                     AS on_delete
             , c.confmatchtype                   AS matching
             , pg_get_constraintdef(c.oid, true) AS definition
             , d.description                     AS relation_comment
        FROM pg_constraint c
                 JOIN pg_class cl ON cl.oid = c.conrelid
                 JOIN pg_namespace cn ON cn.oid = cl.relnamespace
                 JOIN pg_class tc ON tc.oid = c.confrelid
                 JOIN pg_namespace tn ON tn.oid = tc.relnamespace
                 LEFT JOIN pg_description d ON d.objoid = c.oid
        WHERE ${scopeFilter('cn.nspname', schema, 'cl.relname', entity)}
          AND c.contype IN ('f')
        ORDER BY table_schema, table_name, constraint_name;`, [], 'getRelations'
    ).catch(handleError(`Failed to get relations`, [], {logger, ignoreErrors}))
}

function buildRelation(r: RawRelation, columnsByIndex: Record<EntityId, { [i: number]: string }>): Relation {
    const src = {schema: r.table_schema, entity: r.table_name}
    const ref = {schema: r.target_schema, entity: r.target_table}
    const srcId = formatEntityRef(src)
    const refId = formatEntityRef(ref)
    return removeUndefined({
        name: r.constraint_name,
        kind: undefined, // 'many-to-one' when not specified
        origin: undefined, // 'fk' when not specified
        src,
        ref,
        attrs: zip(r.table_columns, r.target_columns).map(([src, ref]) => ({src: [columnsByIndex[srcId][src]], ref: [columnsByIndex[refId][ref]]})),
        polymorphic: undefined,
        doc: r.relation_comment || undefined,
        extra: undefined
    } as Relation)
}

export type RawTypeKind = 'b' | 'c' | 'd' | 'e' | 'p' | 'r' | 'm' // b: base, c: composite, d: domain, e: enum, p: pseudo-type, r: range, m: multirange
export type RawTypeCategory = 'A' | 'B' | 'C' | 'D' | 'E' | 'G' | 'I' | 'N' | 'P' | 'R' | 'S' | 'T' | 'U' | 'V' | 'X' | 'Z' // A: array, B: bool, C: composite, D: date, E: enum, G: geo, I: inet, N: numeric, P: pseudo, R: range, S: string, T: timespan, U: user-defined, V: bit, X: unknown, Z: internal
export type RawType = {
    type_owner: string
    type_schema: string
    type_name: string
    type_kind: RawTypeKind
    type_category: RawTypeCategory
    type_values: string[]
    type_len: number
    type_delimiter: string
    type_default: string | null
    type_comment: string | null
}

export const getTypes = ({schema, entity, logger, ignoreErrors}: ConnectorSchemaOpts) => async (conn: Conn): Promise<RawType[]> => {
    // https://www.postgresql.org/docs/current/catalog-pg-type.html: stores data types
    // https://www.postgresql.org/docs/current/catalog-pg-namespace.html: stores namespaces. A namespace is the structure underlying SQL schemas: each namespace can have a separate collection of relations, types, etc. without name conflicts.
    // https://www.postgresql.org/docs/current/catalog-pg-authid.html
    // https://www.postgresql.org/docs/current/catalog-pg-class.html: catalogs tables and most everything else that has columns or is otherwise similar to a table. This includes indexes (but see also pg_index), sequences (but see also pg_sequence), views, materialized views, composite types, and TOAST tables; see relkind.
    // https://www.postgresql.org/docs/current/catalog-pg-enum.html: values and labels for each enum type
    // https://www.postgresql.org/docs/current/catalog-pg-description.html: stores optional descriptions (comments) for each database object.
    // `(c.relkind IS NULL OR c.relkind = 'c')`: avoid table types
    // `tt.oid IS NULL`: avoid array types
    return conn.query<RawType>(`
        SELECT min(o.rolname)                    AS type_owner
             , min(n.nspname)                    AS type_schema
             , t.typname                         AS type_name
             , t.typtype                         AS type_kind
             , t.typcategory                     AS type_category
             , array_agg(e.enumlabel)::varchar[] AS type_values
             , t.typlen                          AS type_len
             , t.typdelim                        AS type_delimiter
             , t.typdefault                      AS type_default
             , min(d.description)                AS type_comment
        FROM pg_type t
                 JOIN pg_namespace n ON n.oid = t.typnamespace
                 JOIN pg_authid o ON o.oid = t.typowner
                 LEFT JOIN pg_class c ON c.oid = t.typrelid
                 LEFT JOIN pg_type tt ON tt.oid = t.typelem AND tt.typarray = t.oid
                 LEFT JOIN pg_enum e ON e.enumtypid = t.oid
                 LEFT JOIN pg_description d ON d.objoid = t.oid
        WHERE ${scopeFilter('n.nspname', schema)}
          AND t.typisdefined
          AND (c.relkind IS NULL OR c.relkind = 'c')
          AND tt.oid IS NULL
        GROUP BY t.oid
        ORDER BY type_schema, type_name;`, [], 'getTypes'
    ).catch(handleError(`Failed to get types`, [], {logger, ignoreErrors}))
}

function buildType(t: RawType): Type {
    return removeUndefined({
        schema: t.type_schema,
        name: t.type_name,
        values: t.type_kind === 'e' ? t.type_values : undefined,
        attrs: undefined,
        definition: undefined,
        doc: t.type_comment,
        extra: undefined
    } as Type)
}

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

function scopeFilter(schemaField: string, schemaScope: SchemaName | undefined, entityField?: string, entityScope?: EntityName) {
    const schemaFilter = schemaScope ? `${schemaField} ${schemaScope.includes('%') ? 'LIKE' : '='} '${schemaScope}'` : `${schemaField} NOT IN ('information_schema', 'pg_catalog')`
    const entityFilter = entityField && entityScope ? ` AND ${entityField} ${entityScope.includes('%') ? 'LIKE' : '='} '${entityScope}'` : ''
    return schemaFilter + entityFilter
}
