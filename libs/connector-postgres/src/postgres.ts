import {parse} from "postgres-array";
import {
    groupBy,
    mapEntriesAsync,
    mapValues,
    mapValuesAsync,
    pluralizeL,
    removeEmpty,
    removeUndefined,
    zip
} from "@azimutt/utils";
import {
    Attribute,
    AttributeName,
    AttributePath,
    attributeRefToId,
    AttributeValue,
    Check,
    ConnectorSchemaOpts,
    connectorSchemaOptsDefaults,
    Database,
    DatabaseKind,
    Entity,
    EntityId,
    EntityRef,
    entityRefFromId,
    entityRefToId,
    formatConnectorScope,
    handleError,
    Index,
    isPolymorphic,
    PrimaryKey,
    Relation,
    schemaToAttributes,
    Type,
    ValueSchema,
    valuesToSchema
} from "@azimutt/models";
import {Conn} from "./connect";
import {buildSqlColumn, buildSqlTable, getTableColumns, scopeWhere} from "./helpers";

export const getSchema = (opts: ConnectorSchemaOpts) => async (conn: Conn): Promise<Database> => {
    const start = Date.now()
    const scope = formatConnectorScope({schema: 'schema', entity: 'table'}, opts)
    opts.logger.log(`Connected to the database${scope ? `, exporting for ${scope}` : ''} ...`)

    // access system tables only
    const blockSize: number = await getBlockSize(opts)(conn)
    const database: RawDatabase = await getDatabase(opts)(conn)
    const tables: RawTable[] = await getTables(opts)(conn)
    opts.logger.log(`Found ${pluralizeL(tables, 'table')} ...`)
    const columns: RawColumn[] = await getColumns(opts)(conn)
    opts.logger.log(`Found ${pluralizeL(columns, 'column')} ...`)
    const constraints: RawConstraint[] = await getConstraints(opts)(conn)
    opts.logger.log(`Found ${pluralizeL(constraints, 'constraint')} ...`)
    const indexes: RawIndex[] = await getIndexes(opts)(conn)
    opts.logger.log(`Found ${pluralizeL(indexes, 'index')} ...`)
    const relations: RawRelation[] = await getRelations(opts)(conn)
    opts.logger.log(`Found ${pluralizeL(relations, 'relation')} ...`)
    const types: RawType[] = await getTypes(opts)(conn)
    opts.logger.log(`Found ${pluralizeL(types, 'type')} ...`)

    // access table data when options are requested
    const columnsByTable = groupByEntity(columns)
    const jsonColumns: Record<EntityId, Record<AttributeName, ValueSchema>> = opts.inferJsonAttributes ? await getJsonColumns(columnsByTable, opts)(conn) : {}
    const polyColumns: Record<EntityId, Record<AttributeName, string[]>> = opts.inferPolymorphicRelations ? await getPolyColumns(columnsByTable, opts)(conn) : {}
    // TODO: pii, join relations...

    // build the database
    const columnsByIndex: Record<EntityId, { [i: number]: string }> = mapValues(columnsByTable, cols => cols.reduce((acc, col) => ({...acc, [col.column_index]: col.column_name}), {}))
    const constraintsByTable = groupByEntity(constraints)
    const indexesByTable = groupByEntity(indexes)
    opts.logger.log(`✔︎ Exported ${pluralizeL(tables, 'table')}, ${pluralizeL(relations, 'relation')} and ${pluralizeL(types, 'type')} from the database!`)
    return removeUndefined({
        entities: tables.map(table => [toEntityId(table), table] as const).map(([id, table]) => buildEntity(
            blockSize,
            table,
            columnsByTable[id] || [],
            columnsByIndex[id] || {},
            constraintsByTable[id] || [],
            indexesByTable[id] || [],
            jsonColumns[id] || {},
            polyColumns[id] || {},
        )),
        relations: relations.map(r => buildRelation(r, columnsByIndex)).filter((rel): rel is Relation => !!rel),
        types: types.map(buildType),
        doc: undefined,
        stats: removeUndefined({
            name: conn.url.db || database.database,
            kind: DatabaseKind.Enum.postgres,
            version: database.version,
            doc: undefined,
            extractedAt: new Date().toISOString(),
            extractionDuration: Date.now() - start,
            size: database.blks_read * blockSize,
        }),
        extra: undefined,
    })
}

// 👇️ Private functions, some are exported only for tests
// If you use them, beware of breaking changes!

const toEntityId = <T extends { table_schema: string, table_name: string }>(value: T): EntityId => entityRefToId({schema: value.table_schema, entity: value.table_name})
const groupByEntity = <T extends { table_schema: string, table_name: string }>(values: T[]): Record<EntityId, T[]> => groupBy(values, toEntityId)

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
        WHERE datname = current_database();`, [], 'getDatabase'
    ).then(res => res[0] || onError).catch(handleError(`Failed to get database info`, onError, opts))
}

export const getBlockSize = (opts: ConnectorSchemaOpts) => async (conn: Conn): Promise<number> => {
    return conn.query<{block_size: number}>(`SHOW block_size;`, [], 'getBlockSize')
        .then(res => res[0]?.block_size || 8192)
        .catch(handleError(`Failed to get block size`, 0, opts))
}

export type RawTable = {
    table_id: number
    // table_owner: string // TODO: `permission denied for table pg_authid`
    table_schema: string
    table_name: string
    table_kind: 'r' | 'v' | 'm' // r: table, v: view, m: materialized view
    table_definition: string | null
    table_partition: string | null
    table_comment: string | null
    attributes_count: number
    checks_count: number
    rows: number | null
    rows_dead: number | null
    blocks: number | null
    idx_blocks: number | null
    seq_scan: number | null
    seq_scan_reads: number | null
    seq_scan_last: Date | null
    idx_scan: number | null
    idx_scan_reads: number | null
    idx_scan_last: Date | null
    analyze_count: number | null
    analyze_last: Date | null
    autoanalyze_count: number | null
    autoanalyze_last: Date | null
    changes_since_analyze: number | null
    vacuum_count: number | null
    vacuum_last: Date | null
    autovacuum_count: number | null
    autovacuum_last: Date | null
    changes_since_vacuum: number | null
    toast_schema: string | null
    toast_name: string | null
    toast_blocks: number | null
    toast_idx_blocks: number | null
}

export const getTables = (opts: ConnectorSchemaOpts) => async (conn: Conn): Promise<RawTable[]> => {
    // https://www.postgresql.org/docs/current/catalog-pg-class.html: catalogs tables and most everything else that has columns or is otherwise similar to a table. This includes indexes (but see also pg_index), sequences (but see also pg_sequence), views, materialized views, composite types, and TOAST tables; see relkind.
    // https://www.postgresql.org/docs/current/catalog-pg-namespace.html: stores namespaces. A namespace is the structure underlying SQL schemas: each namespace can have a separate collection of relations, types, etc. without name conflicts.
    // https://www.postgresql.org/docs/current/catalog-pg-authid.html: store users
    // https://www.postgresql.org/docs/current/catalog-pg-description.html: stores optional descriptions (comments) for each database object.
    // https://www.postgresql.org/docs/current/functions-info.html#FUNCTIONS-INFO-CATALOG
    // https://www.postgresql.org/docs/current/monitoring-stats.html#MONITORING-PG-STAT-ALL-TABLES-VIEW: stats on tables
    // https://www.postgresql.org/docs/current/monitoring-stats.html#MONITORING-PG-STATIO-ALL-TABLES-VIEW: stats on table blocks
    // `c.relkind IN ('r', 'v', 'm')`: get only tables, view and materialized views
    const sCols = await getTableColumns('pg_catalog', 'pg_stat_all_tables', opts)(conn) // check column presence to include them or not
    return conn.query<RawTable>(`
        SELECT c.oid                       AS table_id
             -- , u.rolname                   AS table_owner
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
             , ${sCols.includes('last_seq_scan') ? 's.last_seq_scan' : 'null           '}             AS seq_scan_last
             , s.idx_scan
             , s.idx_tup_fetch             AS idx_scan_reads
             , ${sCols.includes('last_idx_scan') ? 's.last_idx_scan' : 'null           '}             AS idx_scan_last
             , s.analyze_count
             , s.last_analyze              AS analyze_last
             , s.autoanalyze_count
             , s.last_autoanalyze          AS autoanalyze_last
             , s.n_mod_since_analyze       AS changes_since_analyze
             , s.vacuum_count
             , s.last_vacuum               AS vacuum_last
             , s.autovacuum_count
             , s.last_autovacuum           AS autovacuum_last
             , ${sCols.includes('n_ins_since_vacuum') ? 's.n_ins_since_vacuum' : 'null                '}        AS changes_since_vacuum
             , tn.nspname                  AS toast_schema
             , tc.relname                  AS toast_name
             , io.toast_blks_read          AS toast_blocks
             , io.tidx_blks_read           AS toast_idx_blocks
        FROM pg_class c
                 JOIN pg_namespace n ON n.oid = c.relnamespace
                 -- JOIN pg_authid u ON u.oid = c.relowner
                 LEFT JOIN pg_description d ON d.objoid = c.oid AND d.objsubid = 0
                 LEFT JOIN pg_class tc ON tc.oid = c.reltoastrelid
                 LEFT JOIN pg_namespace tn ON tn.oid = tc.relnamespace
                 LEFT JOIN pg_stat_all_tables s ON s.relid = c.oid
                 LEFT JOIN pg_statio_all_tables io ON io.relid = c.oid
        WHERE c.relkind IN ('r', 'v', 'm')
          AND ${scopeWhere({schema: 'n.nspname', entity: 'c.relname'}, opts)}
        ORDER BY table_schema, table_name;`, [], 'getTables'
    ).catch(handleError(`Failed to get tables`, [], opts))
}

function buildEntity(blockSize: number, table: RawTable, columns: RawColumn[], columnsByIndex: { [i: number]: string }, constraints: RawConstraint[], indexes: RawIndex[], jsonColumns: Record<AttributeName, ValueSchema>, polyColumns: Record<AttributeName, string[]>): Entity {
    return removeEmpty({
        schema: table.table_schema,
        name: table.table_name,
        kind: table.table_kind === 'v' ? 'view' as const : table.table_kind === 'm' ? 'materialized view' as const : undefined,
        def: table.table_definition || undefined,
        attrs: columns.slice(0)
            .sort((a, b) => a.column_index - b.column_index)
            .map(c => buildAttribute(c, jsonColumns[c.column_name], polyColumns[c.column_name], table.rows)),
        pk: constraints.filter(c => c.constraint_type === 'p').map(c => buildPrimaryKey(c, columnsByIndex))[0] || undefined,
        indexes: indexes.map(i => buildIndex(blockSize, i, columnsByIndex)),
        checks: constraints.filter(c => c.constraint_type === 'c').map(c => buildCheck(c, columnsByIndex)),
        doc: table.table_comment || undefined,
        stats: removeUndefined({
            rows: table.rows || undefined,
            rowsDead: table.rows_dead || undefined,
            size: table.blocks ? table.blocks * blockSize : undefined,
            sizeIdx: table.idx_blocks ? table.idx_blocks * blockSize : undefined,
            sizeToast: table.toast_blocks ? table.toast_blocks * blockSize : undefined,
            sizeToastIdx: table.toast_idx_blocks ? table.toast_idx_blocks * blockSize : undefined,
            scanSeq: table.seq_scan || undefined,
            scanSeqLast: (table.seq_scan_last || undefined)?.toISOString(),
            scanIdx: table.idx_scan || undefined,
            scanIdxLast: (table.idx_scan_last || undefined)?.toISOString(),
            analyzeLast: (table.analyze_last || table.autoanalyze_last || undefined)?.toISOString(),
            analyzeLag: table.changes_since_analyze || undefined,
            vacuumLast: (table.vacuum_last || table.autovacuum_last || undefined)?.toISOString(),
            vacuumLag: table.changes_since_vacuum || undefined,
        }),
        extra: undefined
    })
}

// https://www.postgresql.org/docs/current/catalog-pg-type.html#CATALOG-TYPCATEGORY-TABLE
export type RawColumn = {
    table_id: number
    // table_owner: string // TODO: `permission denied for table pg_authid`
    table_schema: string
    table_name: string
    table_kind: 'r' | 'v' | 'm' // r: table, v: view, m: materialized view
    column_index: number
    column_name: string
    column_type: string
    column_type_name: string
    column_type_len: number
    column_type_cat: RawTypeCategory
    column_nullable: boolean
    column_default: string | null
    column_generated: boolean
    column_comment: string | null
    nulls: number | null // percentage of nulls (between 0 & 1)
    avg_len: number | null
    cardinality: number | null // if negative: negative of distinct values divided by the number of rows (% of uniqueness)
    common_vals: string | null
    common_freqs: number[] | null
    histogram: string | null
}

export const getColumns = (opts: ConnectorSchemaOpts) => async (conn: Conn): Promise<RawColumn[]> => {
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
             -- , u.rolname                            AS table_owner
             , n.nspname                            AS table_schema
             , c.relname                            AS table_name
             , c.relkind                            AS table_kind
             , a.attnum                             AS column_index
             , a.attname                            AS column_name
             , format_type(a.atttypid, a.atttypmod) AS column_type
             , t.typname                            AS column_type_name
             , t.typlen                             AS column_type_len
             , t.typcategory                        AS column_type_cat
             , NOT a.attnotnull                     AS column_nullable
             , pg_get_expr(ad.adbin, ad.adrelid)    AS column_default
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
                 -- JOIN pg_authid u ON u.oid = c.relowner
                 JOIN pg_type t ON t.oid = a.atttypid
                 LEFT JOIN pg_attrdef ad ON ad.adrelid = c.oid AND ad.adnum = a.attnum
                 LEFT JOIN pg_description d ON d.objoid = c.oid AND d.objsubid = a.attnum
                 LEFT JOIN pg_stats s ON s.schemaname = n.nspname AND s.tablename = c.relname AND s.attname = a.attname
        WHERE c.relkind IN ('r', 'v', 'm')
          AND a.attnum > 0
          AND a.atttypid != 0
          AND ${scopeWhere({schema: 'n.nspname', entity: 'c.relname'}, opts)}
        ORDER BY table_schema, table_name, column_index;`, [], 'getColumns'
    ).catch(handleError(`Failed to get columns`, [], opts))
}

function buildAttribute(c: RawColumn, jsonColumn: ValueSchema | undefined, values: string[] | undefined, rows: number | null): Attribute {
    return removeEmpty({
        name: c.column_name,
        type: c.column_type,
        null: c.column_nullable || undefined,
        gen: c.column_generated || undefined,
        default: c.column_default || undefined,
        attrs: jsonColumn ? schemaToAttributes(jsonColumn) : undefined,
        doc: c.column_comment || undefined,
        stats: removeUndefined({
            nulls: c.nulls || undefined,
            bytesAvg: c.avg_len || undefined,
            cardinality: c.cardinality === null ? undefined : c.cardinality >= 0 ? c.cardinality : rows !== null && rows > 0 ? rows * c.cardinality * -1 : undefined, // if <0, % of rows
            commonValues: c.common_vals && c.common_freqs ? zip(parseValues(c.common_vals, c.column_type_cat, c.column_type_name), c.common_freqs).map(([value, freq]) => ({value, freq})) : undefined,
            distinctValues: values,
            histogram: c.histogram ? parseValues(c.histogram, c.column_type_cat, c.column_type_name) : undefined,
            min: undefined,
            max: undefined,
        }),
        extra: undefined,
    })
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

export const getConstraints = (opts: ConnectorSchemaOpts) => async (conn: Conn): Promise<RawConstraint[]> => {
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
        WHERE c.contype IN ('p', 'c')
          AND ${scopeWhere({schema: 'cn.nspname', entity: 'cl.relname'}, opts)}
        ORDER BY table_schema, table_name, constraint_name;`, [], 'getConstraints'
    ).catch(handleError(`Failed to get constraints`, [], opts))
}

function buildPrimaryKey(c: RawConstraint, columns: { [i: number]: string }): PrimaryKey {
    return removeUndefined({
        name: c.constraint_name,
        attrs: c.columns.map(i => [getColumnName(columns, i)]),
        doc: c.constraint_comment || undefined,
        stats: undefined,
        extra: undefined
    })
}

function buildCheck(c: RawConstraint, columns: { [i: number]: string }): Check {
    return removeUndefined({
        name: c.constraint_name,
        attrs: c.columns.map(i => [getColumnName(columns, i)]),
        predicate: c.definition,
        doc: c.constraint_comment || undefined,
        stats: undefined,
        extra: undefined
    })
}

type RawIndex = {
    table_schema: string
    table_name: string
    index_id: number
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

export const getIndexes = (opts: ConnectorSchemaOpts) => async (conn: Conn): Promise<RawIndex[]> => {
    // https://www.postgresql.org/docs/current/catalog-pg-index.html: contains part of the information about indexes. The rest is mostly in pg_class.
    // https://www.postgresql.org/docs/current/catalog-pg-class.html: catalogs tables and most everything else that has columns or is otherwise similar to a table. This includes indexes (but see also pg_index), sequences (but see also pg_sequence), views, materialized views, composite types, and TOAST tables; see relkind.
    // https://www.postgresql.org/docs/current/catalog-pg-description.html: stores optional descriptions (comments) for each database object.
    // https://www.postgresql.org/docs/current/monitoring-stats.html#MONITORING-PG-STAT-ALL-INDEXES-VIEW: stats on indexes
    // https://www.postgresql.org/docs/current/functions-info.html#FUNCTIONS-INFO-CATALOG
    // `i.indisprimary = false`: primary keys are fetch an other way
    const sCols = await getTableColumns('pg_catalog', 'pg_stat_all_indexes', opts)(conn) // check column presence to include them or not
    return conn.query<RawIndex>(`
        SELECT s.schemaname                           AS table_schema
             , s.relname                              AS table_name
             , s.indexrelid                           AS index_id
             , s.indexrelname                         AS index_name
             , i.indkey::integer[]                    AS columns
             , i.indisunique                          AS is_unique
             , pg_get_expr(i.indpred, i.indrelid)     AS partial
             , pg_get_indexdef(i.indexrelid, 0, true) AS definition
             , c.reltuples                            AS rows
             , c.relpages                             AS blocks
             , s.idx_scan                             AS idx_scan
             , s.idx_tup_read                         AS idx_scan_reads
             , ${sCols.includes('last_idx_scan') ? 's.last_idx_scan' : 'null           '}                        AS idx_scan_last
             , d.description                          AS index_comment
        FROM pg_index i
                 JOIN pg_class c ON c.oid = i.indexrelid
                 JOIN pg_stat_all_indexes s ON s.indexrelid = i.indexrelid
                 LEFT JOIN pg_description d ON d.objoid = i.indexrelid
        WHERE i.indisprimary = false
          AND ${scopeWhere({schema: 's.schemaname', entity: 's.relname'}, opts)}
        ORDER BY table_schema, table_name, index_name;`, [], 'getIndexes'
    ).then(rows => rows.map(row => ({
        ...row,
        definition: row.definition.indexOf(' USING ') > 0 ? row.definition.split(' USING ')[1].trim() : row.definition
    }))).catch(handleError(`Failed to get indexes`, [], opts))
}

function buildIndex(blockSize: number, index: RawIndex, columns: { [i: number]: string }): Index {
    return removeUndefined({
        name: index.index_name || index.index_id.toString(),
        attrs: index.columns.map(i => [getColumnName(columns, i)]), // TODO: handle indexes with functions or on nested json columns
        unique: index.is_unique || undefined,
        partial: index.partial || undefined,
        definition: index.definition,
        doc: index.index_comment || undefined,
        stats: removeUndefined({
            size: index.blocks * blockSize,
            scans: index.idx_scan,
            scansLast: (index.idx_scan_last || undefined)?.toISOString(),
        }),
        extra: undefined
    })
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

export const getRelations = (opts: ConnectorSchemaOpts) => async (conn: Conn): Promise<RawRelation[]> => {
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
        WHERE c.contype IN ('f')
          AND ${scopeWhere({schema: 'cn.nspname', entity: 'cl.relname'}, opts)}
        ORDER BY table_schema, table_name, constraint_name;`, [], 'getRelations'
    ).catch(handleError(`Failed to get relations`, [], opts))
}

function buildRelation(r: RawRelation, columnsByIndex: Record<EntityId, { [i: number]: string }>): Relation | undefined {
    const src = {schema: r.table_schema, entity: r.table_name}
    const ref = {schema: r.target_schema, entity: r.target_table}
    const srcId = entityRefToId(src)
    const refId = entityRefToId(ref)
    const rel = {
        name: r.constraint_name,
        kind: undefined, // 'many-to-one' when not specified
        origin: undefined, // 'fk' when not specified
        src,
        ref,
        attrs: zip(r.table_columns, r.target_columns)
            .map(([src, ref]) => {
                if (columnsByIndex[srcId] && columnsByIndex[srcId][src] && columnsByIndex[refId] && columnsByIndex[refId][ref]) {
                    return {src: [columnsByIndex[srcId][src]], ref: [columnsByIndex[refId][ref]]}
                } else {
                    return undefined
                }
            })
            .filter((attr): attr is { src: AttributePath, ref: AttributePath } => !!attr),
        polymorphic: undefined,
        doc: r.relation_comment || undefined,
        extra: undefined
    }
    // don't keep relation if columns are not found :/
    // should not happen if errors are not skipped
    return rel.attrs.length > 0 ? removeUndefined(rel) : undefined
}

export type RawTypeKind = 'b' | 'c' | 'd' | 'e' | 'p' | 'r' | 'm' // b: base, c: composite, d: domain, e: enum, p: pseudo-type, r: range, m: multirange
export type RawTypeCategory = 'A' | 'B' | 'C' | 'D' | 'E' | 'G' | 'I' | 'N' | 'P' | 'R' | 'S' | 'T' | 'U' | 'V' | 'X' | 'Z' // A: array, B: bool, C: composite, D: date, E: enum, G: geo, I: inet, N: numeric, P: pseudo, R: range, S: string, T: timespan, U: user-defined, V: bit, X: unknown, Z: internal
export type RawType = {
    // type_owner: string // TODO: `permission denied for table pg_authid`
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

export const getTypes = (opts: ConnectorSchemaOpts) => async (conn: Conn): Promise<RawType[]> => {
    // https://www.postgresql.org/docs/current/catalog-pg-type.html: stores data types
    // https://www.postgresql.org/docs/current/catalog-pg-namespace.html: stores namespaces. A namespace is the structure underlying SQL schemas: each namespace can have a separate collection of relations, types, etc. without name conflicts.
    // https://www.postgresql.org/docs/current/catalog-pg-authid.html
    // https://www.postgresql.org/docs/current/catalog-pg-class.html: catalogs tables and most everything else that has columns or is otherwise similar to a table. This includes indexes (but see also pg_index), sequences (but see also pg_sequence), views, materialized views, composite types, and TOAST tables; see relkind.
    // https://www.postgresql.org/docs/current/catalog-pg-enum.html: values and labels for each enum type
    // https://www.postgresql.org/docs/current/catalog-pg-description.html: stores optional descriptions (comments) for each database object.
    // `(c.relkind IS NULL OR c.relkind = 'c')`: avoid table types
    // `tt.oid IS NULL`: avoid array types
    return conn.query<RawType>(`
        SELECT min(n.nspname)                                        AS type_schema
             -- , min(o.rolname)                                        AS type_owner
             , t.typname                                             AS type_name
             , t.typtype                                             AS type_kind
             , t.typcategory                                         AS type_category
             , array_remove(array_agg(e.enumlabel), null)::varchar[] AS type_values
             , t.typlen                                              AS type_len
             , t.typdelim                                            AS type_delimiter
             , t.typdefault                                          AS type_default
             , min(d.description)                                    AS type_comment
        FROM pg_type t
                 JOIN pg_namespace n ON n.oid = t.typnamespace
                 -- JOIN pg_authid o ON o.oid = t.typowner
                 LEFT JOIN pg_class c ON c.oid = t.typrelid
                 LEFT JOIN pg_type tt ON tt.oid = t.typelem AND tt.typarray = t.oid
                 LEFT JOIN pg_enum e ON e.enumtypid = t.oid
                 LEFT JOIN pg_description d ON d.objoid = t.oid
        WHERE t.typisdefined
          AND (c.relkind IS NULL OR c.relkind = 'c')
          AND tt.oid IS NULL
          AND ${scopeWhere({schema: 'n.nspname'}, opts)}
        GROUP BY t.oid, t.typname, t.typtype, t.typcategory, t.typlen, t.typdelim, t.typdefault
        ORDER BY type_schema, type_name;`, [], 'getTypes'
    ).catch(handleError(`Failed to get types`, [], opts))
}

function buildType(t: RawType): Type {
    return removeUndefined({
        schema: t.type_schema,
        name: t.type_name,
        values: t.type_kind === 'e' ? t.type_values : undefined,
        attrs: undefined,
        definition: undefined,
        doc: t.type_comment || undefined,
        extra: undefined
    })
}

// getTriggers: pg_get_triggerdef
// getFunctions / getProcedures: pg_get_functiondef, pg_get_function_arguments, pg_get_function_identity_arguments, pg_get_function_result (https://www.postgresql.org/docs/current/functions-info.html#FUNCTIONS-INFO-CATALOG)

const getJsonColumns = (columns: Record<EntityId, RawColumn[]>, opts: ConnectorSchemaOpts) => async (conn: Conn): Promise<Record<EntityId, Record<AttributeName, ValueSchema>>> => {
    opts.logger.log('Inferring JSON columns ...')
    return mapEntriesAsync(columns, (entityId, tableCols) => {
        const ref = entityRefFromId(entityId)
        const jsonCols = tableCols.filter(c => c.column_type === 'jsonb')
        return mapValuesAsync(Object.fromEntries(jsonCols.map(c => [c.column_name, c.column_name])), c =>
            getSampleValues(ref, [c], opts)(conn).then(valuesToSchema)
        )
    })
}

const getSampleValues = (ref: EntityRef, attribute: AttributePath, opts: ConnectorSchemaOpts) => async (conn: Conn): Promise<AttributeValue[]> => {
    const sqlTable = buildSqlTable(ref)
    const sqlColumn = buildSqlColumn(attribute)
    const sampleSize = opts.sampleSize || connectorSchemaOptsDefaults.sampleSize
    return conn.query<{value: AttributeValue}>(`SELECT ${sqlColumn} AS value FROM ${sqlTable} WHERE ${sqlColumn} IS NOT NULL LIMIT ${sampleSize};`, [], 'getSampleValues')
        .then(rows => rows.map(row => row.value))
        .catch(handleError(`Failed to get sample values for '${attributeRefToId({...ref, attribute})}'`, [], opts))
}

const getPolyColumns = (columns: Record<EntityId, RawColumn[]>, opts: ConnectorSchemaOpts) => async (conn: Conn): Promise<Record<EntityId, Record<AttributeName, string[]>>> => {
    opts.logger.log('Inferring polymorphic relations ...')
    return mapEntriesAsync(columns, (entityId, tableCols) => {
        const ref = entityRefFromId(entityId)
        const colNames = tableCols.map(c => c.column_name)
        const polyCols = tableCols.filter(c => isPolymorphic(c.column_name, colNames))
        return mapValuesAsync(Object.fromEntries(polyCols.map(c => [c.column_name, c.column_name])), c =>
            getDistinctValues(ref, [c], opts)(conn).then(values => values.filter((v): v is string => typeof v === 'string'))
        )
    })
}

export const getDistinctValues = (ref: EntityRef, attribute: AttributePath, opts: ConnectorSchemaOpts) => async (conn: Conn): Promise<AttributeValue[]> => {
    const sqlTable = buildSqlTable(ref)
    const sqlColumn = buildSqlColumn(attribute)
    const sampleSize = opts.sampleSize || connectorSchemaOptsDefaults.sampleSize
    return conn.query<{value: AttributeValue}>(`SELECT DISTINCT ${sqlColumn} AS value FROM ${sqlTable} WHERE ${sqlColumn} IS NOT NULL ORDER BY value LIMIT ${sampleSize};`, [], 'getDistinctValues')
        .then(rows => rows.map(row => row.value))
        .catch(err => err instanceof Error && err.message.match(/materialized view "[^"]+" has not been populated/) ? [] : Promise.reject(err))
        .catch(handleError(`Failed to get distinct values for '${attributeRefToId({...ref, attribute})}'`, [], opts))
}

function getColumnName(columns: { [i: number]: string }, index: number): AttributeName {
    return columns[index] || (index === 0 ? '*expression*' : 'unknown')
}
