import {
    groupBy,
    mapEntriesAsync,
    mapValuesAsync,
    pluralize,
    pluralizeL,
    removeEmpty,
    removeUndefined,
    zip,
} from "@azimutt/utils";
import {
    Attribute,
    AttributeName,
    AttributePath,
    attributePathFromId,
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
    valuesToSchema,
} from "@azimutt/models";
import {buildSqlColumn, buildSqlTable, ScopeOpts, scopeWhere} from "./helpers";
import {Conn} from "./connect";

export const getSchema = (opts: ConnectorSchemaOpts) => async (conn: Conn): Promise<Database> => {
    const start = Date.now()
    const scope = formatConnectorScope({schema: 'schema', entity: 'table'}, opts)
    opts.logger.log(`Connected to the database${scope ? `, exporting for ${scope}` : ''} ...`)

    // access system tables only
    const database: RawDatabase = await getDatabase(opts)(conn)
    const blockSizes: BlockSizes = await getBlockSizes(opts)(conn)
    const oracleUsers: string[] = await getOracleUsers(opts)(conn)
    const opts2: ScopeOpts = {...opts, oracleUsers}
    const tables: RawTable[] = await getTables(opts2)(conn)
    const views: RawView[] = await getViews(opts2)(conn)
    opts.logger.log(`Found ${pluralize(tables.length + views.length, 'table')} ...`)
    const columns: RawColumn[] = await getColumns(opts2)(conn)
    opts.logger.log(`Found ${pluralizeL(columns, 'column')} ...`)
    const constraints: RawConstraint[] = await getConstraints(opts2)(conn)
    opts.logger.log(`Found ${pluralizeL(constraints, 'constraint')} ...`)
    const indexes: RawIndex[] = await getIndexes(opts2)(conn)
    opts.logger.log(`Found ${pluralizeL(indexes, 'index')} ...`)
    const relations: RawRelation[] = await getRelations(opts2)(conn)
    opts.logger.log(`Found ${pluralizeL(relations, 'relation')} ...`)
    const types: RawType[] = await getTypes(opts2)(conn)
    opts.logger.log(`Found ${pluralizeL(types, 'type')} ...`)

    // access table data when options are requested
    const columnsByTable = groupByEntity(columns)
    const jsonColumns: Record<EntityId, Record<AttributeName, ValueSchema>> = opts.inferJsonAttributes ? await getJsonColumns(columnsByTable, opts)(conn) : {}
    const polyColumns: Record<EntityId, Record<AttributeName, string[]>> = opts.inferPolymorphicRelations ? await getPolyColumns(columnsByTable, opts)(conn) : {}
    // TODO: pii, join relations...

    // build the database
    const constraintsByTable = groupByEntity(constraints)
    const indexesByTable = groupByEntity(indexes)
    opts.logger.log(`✔︎ Exported ${pluralize(tables.length + views.length, 'table')}, ${pluralizeL(relations, 'relation')} and ${pluralizeL(types, 'type')} from the database!`)
    return removeUndefined({
        entities: tables.map(table => [toEntityId(table), table] as const).map(([id, table]) => buildTableEntity(
            blockSizes[table.TABLE_TABLESPACE || ''] || 8192,
            table,
            columnsByTable[id] || [],
            constraintsByTable[id] || [],
            indexesByTable[id] || [],
            jsonColumns[id] || {},
            polyColumns[id] || {},
        )).concat(views.map(view => [toEntityId(view), view] as const).map(([id, view]) => buildViewEntity(
            view,
            columnsByTable[id] || [],
            jsonColumns[id] || {},
            polyColumns[id] || {},
        ))),
        relations: relations.map(buildRelation).filter((rel): rel is Relation => !!rel),
        types: types.map(buildType),
        doc: undefined,
        stats: removeUndefined({
            name: conn.url.db || database.DATABASE,
            kind: DatabaseKind.Enum.oracle,
            version: database.VERSION,
            size: database.BYTES,
        }),
        extra: removeUndefined({
            source: `Oracle connector`,
            createdAt: new Date().toISOString(),
            creationTimeMs: Date.now() - start,
        }),
    })
}

// 👇️ Private functions, some are exported only for tests
// If you use them, beware of breaking changes!

const toEntityId = <T extends { TABLE_OWNER: string; TABLE_NAME: string }>(value: T): EntityId => entityRefToId({schema: value.TABLE_OWNER, entity: value.TABLE_NAME})
const groupByEntity = <T extends { TABLE_OWNER: string; TABLE_NAME: string }>(values: T[]): Record<EntityId, T[]> => groupBy(values, toEntityId)

export type RawDatabase = {
    DATABASE: string | undefined
    VERSION: string | undefined
    BYTES: number | undefined
}

export const getDatabase = (opts: ConnectorSchemaOpts) => async (conn: Conn): Promise<RawDatabase> => {
    // https://docs.oracle.com/en/database/oracle/oracle-database/23/refrn/V-DATABASE.html
    // https://docs.oracle.com/en/database/oracle/oracle-database/23/refrn/V-VERSION.html
    // https://docs.oracle.com/en/database/oracle/oracle-database/23/refrn/DBA_DATA_FILES.html
    const DATABASE: string | undefined = await conn.query<{NAME: string}>(`SELECT NAME FROM V$DATABASE`, [], 'getDatabaseName')
        .then(res => res[0]?.NAME, handleError(`Failed to get database name`, undefined, {...opts, ignoreErrors: true}))
    const VERSION: string | undefined = await conn.query<{VERSION: string}>(`SELECT BANNER AS VERSION FROM V$VERSION FETCH NEXT 1 ROW ONLY`, [], 'getDatabaseVersion')
        .then(res => res[0]?.VERSION, handleError(`Failed to get database version`, undefined, {...opts, ignoreErrors: true}))
    const BYTES: number | undefined = await conn.query<{BYTES: number}>(`SELECT SUM(BYTES) AS BYTES FROM DBA_DATA_FILES`, [], 'getDatabaseSize')
        .then(res => res[0]?.BYTES, handleError(`Failed to get database size`, undefined, {...opts, ignoreErrors: true}))
    return {DATABASE, VERSION, BYTES}
}

export type RawBlockSizes = { TABLESPACE_NAME: string, BLOCK_SIZE: number }
export type BlockSizes = { [tablespace: string]: number }

export const getBlockSizes = (opts: ConnectorSchemaOpts) => async (conn: Conn): Promise<BlockSizes> => {
    // https://docs.oracle.com/en/database/oracle/oracle-database/23/refrn/DBA_TABLESPACES.html
    return conn.query<RawBlockSizes>(`SELECT TABLESPACE_NAME, BLOCK_SIZE FROM DBA_TABLESPACES`, [], 'getBlockSizes')
        .then(res => res.reduce((acc, v) => ({...acc, [v.TABLESPACE_NAME]: v.BLOCK_SIZE}), {}))
        .catch(handleError(`Failed to get block sizes`, {}, opts))
}

// used to ignore objects owned by Oracle users (see scopeWhere schemaFilter)
export const getOracleUsers = (opts: ConnectorSchemaOpts) => async (conn: Conn): Promise<string[]> => {
    // https://docs.oracle.com/en/database/oracle/oracle-database/23/refrn/ALL_USERS.html
    return conn.query<{USERNAME: string}>(`SELECT USERNAME FROM ALL_USERS WHERE ORACLE_MAINTAINED='Y'`, [], 'getOracleUsers')
        .then(res => res.map(r => r.USERNAME))
        .catch(handleError(`Failed to get oracle users`, [], opts))
}

export type RawTable = {
    TABLE_OWNER: string
    TABLE_CLUSTER: string | null
    TABLE_TABLESPACE: string | null
    TABLE_NAME: string
    TABLE_ROWS: number | null
    TABLE_BLOCKS: number | null
    ANALYZED_LAST: Date | null
    PARTITIONED: 'YES' | 'NO'
    NESTED: 'YES' | 'NO'
    TABLE_COMMENT: string | null
    MVIEW_DEFINITION: string | null
    MVIEW_REFRESHED: Date | null
    MVIEW_COMMENT: string | null
}

export const getTables = (opts: ScopeOpts) => async (conn: Conn): Promise<RawTable[]> => {
    // https://docs.oracle.com/en/database/oracle/oracle-database/23/refrn/ALL_ALL_TABLES.html
    // https://docs.oracle.com/en/database/oracle/oracle-database/23/refrn/ALL_TAB_COMMENTS.html
    // https://docs.oracle.com/en/database/oracle/oracle-database/23/refrn/ALL_MVIEWS.html
    // https://docs.oracle.com/en/database/oracle/oracle-database/23/refrn/ALL_MVIEW_COMMENTS.html
    return conn.query<RawTable>(`
        SELECT t.OWNER              AS TABLE_OWNER
             , t.CLUSTER_NAME       AS TABLE_CLUSTER
             , t.TABLESPACE_NAME    AS TABLE_TABLESPACE
             , t.TABLE_NAME         AS TABLE_NAME
             , t.NUM_ROWS           AS TABLE_ROWS
             , t.BLOCKS             AS TABLE_BLOCKS
             , t.LAST_ANALYZED      AS ANALYZED_LAST
             , t.PARTITIONED        AS PARTITIONED
             , t.NESTED             AS NESTED
             , tc.COMMENTS          AS TABLE_COMMENT
             , mv.QUERY             AS MVIEW_DEFINITION
             , mv.LAST_REFRESH_DATE AS MVIEW_REFRESHED
             , vc.COMMENTS          AS MVIEW_COMMENT
        FROM ALL_ALL_TABLES t
                 LEFT JOIN ALL_TAB_COMMENTS tc ON tc.OWNER = t.OWNER AND tc.TABLE_NAME = t.TABLE_NAME AND tc.TABLE_TYPE='TABLE'
                 LEFT JOIN ALL_MVIEWS mv ON mv.OWNER=t.OWNER AND mv.MVIEW_NAME=t.TABLE_NAME
                 LEFT JOIN ALL_MVIEW_COMMENTS vc ON vc.OWNER = t.OWNER AND vc.MVIEW_NAME = t.TABLE_NAME
        WHERE ${scopeWhere({schema: 't.OWNER', entity: 't.TABLE_NAME'}, opts)}`, [], 'getTables'
    ).catch(handleError(`Failed to get tables`, [], opts))
}

function buildTableEntity(blockSize: number, table: RawTable, columns: RawColumn[], constraints: RawConstraint[], indexes: RawIndex[], jsonColumns: Record<AttributeName, ValueSchema>, polyColumns: Record<AttributeName, string[]>): Entity {
    return removeEmpty({
        schema: table.TABLE_OWNER || undefined,
        name: table.TABLE_NAME,
        kind: table.MVIEW_DEFINITION ? 'materialized view' as const : undefined,
        def: table.MVIEW_DEFINITION || undefined,
        attrs: columns?.slice(0)
            ?.sort((a, b) => a.COLUMN_INDEX - b.COLUMN_INDEX)
            ?.map(c => buildAttribute(c, jsonColumns[c.COLUMN_NAME], polyColumns[c.COLUMN_NAME])) || [],
        pk: constraints.filter(c => c.CONSTRAINT_TYPE === 'P').map(buildPrimaryKey)[0] || undefined,
        indexes: indexes.map(i => buildIndex(blockSize, i)),
        checks: constraints.filter(c => c.CONSTRAINT_TYPE === 'C').map(buildCheck),
        doc: table.TABLE_COMMENT || table.MVIEW_COMMENT || undefined,
        stats: removeUndefined({
            rows: table.TABLE_ROWS || undefined,
            rowsDead: undefined,
            size: table.TABLE_BLOCKS ? table.TABLE_BLOCKS * blockSize : undefined,
            sizeIdx: undefined,
            sizeToast: undefined,
            sizeToastIdx: undefined,
            scanSeq: undefined,
            scanSeqLast: undefined,
            scanIdx: undefined,
            scanIdxLast: undefined,
            analyzeLast: table.ANALYZED_LAST?.toISOString(),
            analyzeLag: undefined,
            vacuumLast: undefined,
            vacuumLag: undefined,
        }),
        extra: removeUndefined({
            cluster: table.TABLE_CLUSTER || undefined,
            tablespace: table.TABLE_TABLESPACE || undefined,
        }),
    })
}

export type RawView = {
    TABLE_OWNER: string
    TABLE_NAME: string
    TABLE_DEFINITION: string
    TABLE_COMMENT: string | null
}

export const getViews = (opts: ScopeOpts) => async (conn: Conn): Promise<RawView[]> => {
    // https://docs.oracle.com/en/database/oracle/oracle-database/23/refrn/ALL_VIEWS.html
    // https://docs.oracle.com/en/database/oracle/oracle-database/23/refrn/ALL_TAB_COMMENTS.html
    return conn.query<RawView>(`
        SELECT v.OWNER     AS TABLE_OWNER
             , v.VIEW_NAME AS TABLE_NAME
             , v.TEXT      AS TABLE_DEFINITION
             , c.COMMENTS  AS TABLE_COMMENT
        FROM ALL_VIEWS v
                 LEFT JOIN ALL_TAB_COMMENTS c ON c.OWNER = v.OWNER AND c.TABLE_NAME = v.VIEW_NAME AND c.TABLE_TYPE = 'VIEW'
        WHERE ${scopeWhere({schema: 'v.OWNER', entity: 'v.VIEW_NAME'}, opts)}`, [], 'getViews'
    ).catch(handleError(`Failed to get views`, [], opts))
}

function buildViewEntity(view: RawView, columns: RawColumn[], jsonColumns: Record<AttributeName, ValueSchema>, polyColumns: Record<AttributeName, string[]>): Entity {
    // TODO: parse TABLE_DEFINITION to get attributes sources and copy outgoing relations
    return removeEmpty({
        schema: view.TABLE_OWNER,
        name: view.TABLE_NAME,
        kind: 'view' as const,
        def: view.TABLE_DEFINITION,
        attrs: columns?.slice(0)
            ?.sort((a, b) => a.COLUMN_INDEX - b.COLUMN_INDEX)
            ?.map(c => buildAttribute(c, jsonColumns[c.COLUMN_NAME], polyColumns[c.COLUMN_NAME])) || [],
        pk: undefined, // TODO
        indexes: [], // TODO
        checks: [], // TODO
        doc: view.TABLE_COMMENT || undefined,
        stats: undefined, // TODO
        extra: undefined,
    })
}

export type RawColumn = {
    TABLE_OWNER: string
    TABLE_NAME: string
    COLUMN_INDEX: number
    COLUMN_NAME: string
    COLUMN_TYPE: string
    COLUMN_TYPE_LEN: number
    COLUMN_NULLABLE: 'Y' | 'N'
    COLUMN_DEFAULT: string | null
    COLUMN_COMMENT: string | null
    CARDINALITY: number | null
    VALUE_LOW: Buffer | null
    VALUE_HIGH: Buffer | null
    NULLS: number | null
    ANALYZED_LAST: Date | null
    AVG_LEN: number | null
    IS_IDENTITY: 'YES' | 'NO'
}

export const getColumns = (opts: ScopeOpts) => async (conn: Conn): Promise<RawColumn[]> => {
    // https://docs.oracle.com/en/database/oracle/oracle-database/23/refrn/DBA_TAB_COLUMNS.html
    // https://docs.oracle.com/en/database/oracle/oracle-database/23/refrn/ALL_COL_COMMENTS.html
    return conn.query<RawColumn>(`
        SELECT c.OWNER           AS TABLE_OWNER
             , c.TABLE_NAME      AS TABLE_NAME
             , c.COLUMN_ID       AS COLUMN_INDEX
             , c.COLUMN_NAME     AS COLUMN_NAME
             , c.DATA_TYPE       AS COLUMN_TYPE
             , c.DATA_LENGTH     AS COLUMN_TYPE_LEN
             , c.NULLABLE        AS COLUMN_NULLABLE
             , c.DATA_DEFAULT    AS COLUMN_DEFAULT
             , cc.COMMENTS       AS COLUMN_COMMENT
             , c.NUM_DISTINCT    AS CARDINALITY
             , c.LOW_VALUE       AS VALUE_LOW
             , c.HIGH_VALUE      AS VALUE_HIGH
             , c.NUM_NULLS       AS NULLS
             , c.LAST_ANALYZED   AS ANALYZED_LAST
             , c.AVG_COL_LEN     AS AVG_LEN
             , c.IDENTITY_COLUMN AS IS_IDENTITY
        FROM ALL_TAB_COLUMNS c
                 LEFT JOIN ALL_COL_COMMENTS cc ON cc.OWNER = c.OWNER AND cc.TABLE_NAME = c.TABLE_NAME AND cc.COLUMN_NAME = c.COLUMN_NAME
        WHERE ${scopeWhere({schema: 'c.OWNER', entity: 'c.TABLE_NAME'}, opts)}`, [], 'getColumns'
    ).catch(handleError(`Failed to get columns`, [], opts))
}

function buildAttribute(c: RawColumn, jsonColumn: ValueSchema | undefined, values: string[] | undefined): Attribute {
    return removeEmpty({
        name: c.COLUMN_NAME,
        type: c.COLUMN_TYPE,
        null: c.COLUMN_NULLABLE == 'Y' || undefined,
        gen: undefined,
        default: c.COLUMN_DEFAULT || undefined,
        attrs: jsonColumn ? schemaToAttributes(jsonColumn) : undefined,
        doc: c.COLUMN_COMMENT || undefined,
        stats: removeUndefined({
            nulls: c.NULLS || undefined,
            bytesAvg: c.AVG_LEN || undefined,
            cardinality: c.CARDINALITY || undefined,
            commonValues: undefined,
            distinctValues: values,
            histogram: undefined,
            min: c.VALUE_LOW?.toString(),
            max: c.VALUE_HIGH?.toString(),
        }),
        extra: undefined,
    })
}

type RawConstraint = {
    CONSTRAINT_NAME: string
    CONSTRAINT_TYPE: 'P' | 'C' // C: Check, P: Primary, U: Unique, R: Referential, V: view check, O: view read only, H: Hash expr, F: Foreign, S: Supplemental logging
    TABLE_OWNER: string
    TABLE_NAME: string
    COLUMN_NAMES: string // comma separated list of column names
    PREDICATE: string | null
    REF_OWNER: string | null
    REF_CONSTRAINT: string | null
    STATUS: 'ENABLED' | 'DISABLED'
    DEFERRABLE: 'DEFERRABLE' | 'NOT DEFERRABLE'
    DEFERRED: 'DEFERRED' | 'IMMEDIATE'
    VALIDATED: 'VALIDATED' | 'NOT VALIDATED'
    INVALID: 'INVALID' | null
    GENERATED: 'USER NAME' | 'GENERATED NAME'
    LAST_CHANGE: Date
    INDEX_OWNER: string | null
    INDEX_NAME: string | null
}

export const getConstraints = (opts: ScopeOpts) => async (conn: Conn): Promise<RawConstraint[]> => {
    // https://docs.oracle.com/en/database/oracle/oracle-database/23/refrn/ALL_CONSTRAINTS.html
    // https://docs.oracle.com/en/database/oracle/oracle-database/23/refrn/ALL_CONS_COLUMNS.html
    // `constraint_type IN ('P', 'C')`: get only primary key and check constraints
    return conn.query<RawConstraint>(`
        SELECT c.CONSTRAINT_NAME                                                AS CONSTRAINT_NAME
             , c.CONSTRAINT_TYPE                                                AS CONSTRAINT_TYPE
             , c.OWNER                                                          AS TABLE_OWNER
             , c.TABLE_NAME                                                     AS TABLE_NAME
             , LISTAGG(cc.COLUMN_NAME, ',') WITHIN GROUP (ORDER BY cc.POSITION) AS COLUMN_NAMES
             , MIN(c.SEARCH_CONDITION_VC)                                       AS PREDICATE
             , MIN(c.R_OWNER)                                                   AS REF_OWNER
             , MIN(c.R_CONSTRAINT_NAME)                                         AS REF_CONSTRAINT
             , MIN(c.STATUS)                                                    AS STATUS
             , MIN(c.DEFERRABLE)                                                AS DEFERRABLE
             , MIN(c.DEFERRED)                                                  AS DEFERRED
             , MIN(c.VALIDATED)                                                 AS VALIDATED
             , MIN(c.INVALID)                                                   AS INVALID
             , MIN(c.GENERATED)                                                 AS GENERATED
             , MIN(c.LAST_CHANGE)                                               AS LAST_CHANGE
             , MIN(c.INDEX_OWNER)                                               AS INDEX_OWNER
             , MIN(c.INDEX_NAME)                                                AS INDEX_NAME
        FROM ALL_CONSTRAINTS c
                 JOIN ALL_CONS_COLUMNS cc ON cc.OWNER = c.OWNER AND cc.TABLE_NAME = c.TABLE_NAME AND cc.CONSTRAINT_NAME = c.CONSTRAINT_NAME
        WHERE c.CONSTRAINT_TYPE IN ('P', 'C')
          AND (c.SEARCH_CONDITION_VC IS NULL OR c.SEARCH_CONDITION_VC NOT LIKE '% IS NOT NULL')
          AND ${scopeWhere({schema: 'c.OWNER', entity: 'c.TABLE_NAME'}, opts)}
        GROUP BY c.CONSTRAINT_NAME, c.CONSTRAINT_TYPE, c.OWNER, c.TABLE_NAME`, [], 'getConstraints'
    ).catch(handleError(`Failed to get constraints`, [], opts))
}

function buildPrimaryKey(c: RawConstraint): PrimaryKey {
    return removeEmpty({
        name: c.CONSTRAINT_NAME,
        attrs: c.COLUMN_NAMES.split(',').map(name => [name]),
        doc: undefined, // no constraint comment in Oracle
        stats: undefined,
        extra: removeUndefined({
            generated: c.GENERATED === 'GENERATED NAME' || undefined,
        }),
    })
}

function buildCheck(c: RawConstraint): Check {
    return removeUndefined({
        name: c.CONSTRAINT_NAME,
        attrs: c.COLUMN_NAMES.split(',').map(name => [name]),
        predicate: c.PREDICATE || '',
        doc: undefined, // no constraint comment in Oracle
        stats: undefined,
        extra: undefined,
    })
}

type RawIndex = {
    INDEX_TABLESPACE: string
    INDEX_NAME: string
    INDEX_TYPE: string
    TABLE_OWNER: string
    TABLE_NAME: string
    TABLE_TYPE: 'TABLE' | 'VIEW' | 'INDEX' | 'SEQUENCE' | 'CLUSTER' | 'SYNONYM' | 'NEXT OBJECT'
    COLUMN_NAMES: string // comma separated list of column names
    COLUMN_VALUES: string // JSON
    IS_UNIQUE: 'UNIQUE' | 'NONUNIQUE'
    CARDINALITY: number
    INDEX_ROWS: number
    ANALYZED_LAST: Date
    GENERATED: 'Y' | 'N'
    PARTITIONED: 'YES' | 'NO'
    IS_CONSTRAINT: 'YES' | 'NO'
    VISIBILITY: 'VISIBLE' | 'INVISIBLE'
}

export const getIndexes = (opts: ScopeOpts) => async (conn: Conn): Promise<RawIndex[]> => {
    // https://docs.oracle.com/en/database/oracle/oracle-database/23/refrn/ALL_INDEXES.html
    // https://docs.oracle.com/en/database/oracle/oracle-database/23/refrn/ALL_IND_COLUMNS.html
    // `i.INDEX_NAME NOT IN`: ignore indexes from primary keys
    const cCols = await getTableColumns('SYS', 'ALL_TAB_COLS', opts)(conn) // check column presence to include them or not
    const values = cCols.includes('DATA_DEFAULT_VC') ? 'JSON_OBJECTAGG(KEY c.COLUMN_NAME VALUE t.DATA_DEFAULT_VC)' : "'{}'                                                     "
    const query =
        `SELECT i.TABLESPACE_NAME                                                     AS INDEX_TABLESPACE
              , i.INDEX_NAME                                                          AS INDEX_NAME
              , i.INDEX_TYPE                                                          AS INDEX_TYPE
              , i.TABLE_OWNER                                                         AS TABLE_OWNER
              , i.TABLE_NAME                                                          AS TABLE_NAME
              , i.TABLE_TYPE                                                          AS TABLE_TYPE
              , LISTAGG(c.COLUMN_NAME, ',') WITHIN GROUP (ORDER BY c.COLUMN_POSITION) AS COLUMN_NAMES
              , ${values}             AS COLUMN_VALUES
              , MIN(i.UNIQUENESS)                                                     AS IS_UNIQUE
              , MIN(i.DISTINCT_KEYS)                                                  AS CARDINALITY
              , MIN(i.NUM_ROWS)                                                       AS INDEX_ROWS
              , MIN(i.LAST_ANALYZED)                                                  AS ANALYZED_LAST
              , MIN(i.GENERATED)                                                      AS GENERATED
              , MIN(i.PARTITIONED)                                                    AS PARTITIONED
              , MIN(i.CONSTRAINT_INDEX)                                               AS IS_CONSTRAINT
              , MIN(i.VISIBILITY)                                                     AS VISIBILITY
         FROM ALL_INDEXES i
                  JOIN ALL_IND_COLUMNS c ON c.INDEX_OWNER = i.OWNER AND c.INDEX_NAME = i.INDEX_NAME
                  LEFT JOIN ALL_TAB_COLS t ON t.OWNER = i.OWNER AND t.TABLE_NAME = i.TABLE_NAME AND t.COLUMN_NAME = c.COLUMN_NAME
         WHERE i.DROPPED != 'YES'
           AND ${scopeWhere({schema: 'i.TABLE_OWNER', entity: 'i.TABLE_NAME'}, opts)}
           AND i.INDEX_NAME NOT IN (SELECT co.CONSTRAINT_NAME FROM ALL_CONSTRAINTS co WHERE co.CONSTRAINT_TYPE = 'P' AND ${scopeWhere({schema: 'co.OWNER', entity: 'co.TABLE_NAME'}, opts)})
         GROUP BY i.TABLESPACE_NAME, i.INDEX_NAME, i.INDEX_TYPE, i.TABLE_OWNER, i.TABLE_NAME, i.TABLE_TYPE`
    return conn.query<RawIndex>(query, [], 'getIndexes').catch(handleError(`Failed to get indexes`, [], opts))
}

function buildIndex(blockSize: number, index: RawIndex): Index {
    const columnValues: { [columnName: string]: string } = JSON.parse(index.COLUMN_VALUES)
    return removeEmpty({
        name: index.INDEX_NAME,
        attrs: index.COLUMN_NAMES.split(',').map(name => {
            // ex: "JSON_VALUE(\"SETTINGS\" FORMAT OSON , '$.plan.name' RETURNING VARCHAR2(4000) NULL ON ERROR TYPE(LAX) )"
            const [, col, path] = (columnValues[name] || '').match(/JSON_VALUE\("([^"]+)"[^,]+, '([^']+)'/) || []
            if (col && path) {
                return [col].concat(path.split('.').slice(1))
            } else {
                return [name]
            }
        }),
        unique: index.IS_UNIQUE === 'UNIQUE' || undefined,
        partial: undefined,
        definition: undefined,
        doc: undefined,
        stats: removeUndefined({
            size: undefined,
            scans: undefined,
            scansLast: index.ANALYZED_LAST?.toISOString() || undefined,
        }),
        extra: removeUndefined({
            tablespace: index.INDEX_TABLESPACE
        }),
    })
}

type RawRelation = {
    CONSTRAINT_NAME: string
    TABLE_OWNER: string
    TABLE_NAME: string
    TABLE_COLUMNS: string // comma separated list of column names
    TARGET_OWNER: string
    TARGET_TABLE: string
    TARGET_COLUMNS: string // comma separated list of column names
    PREDICATE: string | null
    STATUS: 'ENABLED' | 'DISABLED'
    DEFERRABLE: 'DEFERRABLE' | 'NOT DEFERRABLE'
    DEFERRED: 'DEFERRED' | 'IMMEDIATE'
    VALIDATED: 'VALIDATED' | 'NOT VALIDATED'
    INVALID: 'INVALID' | null
    GENERATED: 'USER NAME' | 'GENERATED NAME'
    LAST_CHANGE: Date
    INDEX_OWNER: string | null
    INDEX_NAME: string | null
    DELETE_RULE: string
}

export const getRelations = (opts: ScopeOpts) => async (conn: Conn): Promise<RawRelation[]> => {
    // https://docs.oracle.com/en/database/oracle/oracle-database/23/refrn/ALL_CONSTRAINTS.html
    // https://docs.oracle.com/en/database/oracle/oracle-database/23/refrn/ALL_CONS_COLUMNS.html
    return conn.query<RawRelation>(`
        SELECT sc.CONSTRAINT_NAME                                                 AS CONSTRAINT_NAME
             , sc.OWNER                                                           AS TABLE_OWNER
             , sc.TABLE_NAME                                                      AS TABLE_NAME
             , LISTAGG(scc.COLUMN_NAME, ',') WITHIN GROUP (ORDER BY scc.POSITION) AS TABLE_COLUMNS
             , tc.OWNER                                                           AS TARGET_OWNER
             , tc.TABLE_NAME                                                      AS TARGET_TABLE
             , LISTAGG(tcc.COLUMN_NAME, ',') WITHIN GROUP (ORDER BY tcc.POSITION) AS TARGET_COLUMNS
             , MIN(sc.SEARCH_CONDITION_VC)                                        AS PREDICATE
             , MIN(sc.STATUS)                                                     AS STATUS
             , MIN(sc.DEFERRABLE)                                                 AS DEFERRABLE
             , MIN(sc.DEFERRED)                                                   AS DEFERRED
             , MIN(sc.VALIDATED)                                                  AS VALIDATED
             , MIN(sc.INVALID)                                                    AS INVALID
             , MIN(sc.GENERATED)                                                  AS GENERATED
             , MIN(sc.LAST_CHANGE)                                                AS LAST_CHANGE
             , MIN(sc.INDEX_OWNER)                                                AS INDEX_OWNER
             , MIN(sc.INDEX_NAME)                                                 AS INDEX_NAME
             , MIN(sc.DELETE_RULE)                                                AS DELETE_RULE
        FROM ALL_CONSTRAINTS sc
                 JOIN ALL_CONS_COLUMNS scc ON scc.OWNER = sc.OWNER AND scc.CONSTRAINT_NAME = sc.CONSTRAINT_NAME
                 JOIN ALL_CONSTRAINTS tc ON tc.OWNER = sc.R_OWNER AND tc.CONSTRAINT_NAME = sc.R_CONSTRAINT_NAME
                 JOIN ALL_CONS_COLUMNS tcc ON tcc.OWNER = tc.OWNER AND tcc.CONSTRAINT_NAME = tc.CONSTRAINT_NAME AND tcc.POSITION = scc.POSITION
        WHERE sc.CONSTRAINT_TYPE = 'R' AND ${scopeWhere({schema: 'sc.OWNER', entity: 'sc.TABLE_NAME'}, opts)}
        GROUP BY sc.CONSTRAINT_NAME, sc.OWNER, sc.TABLE_NAME, tc.OWNER, tc.TABLE_NAME`, [], 'getRelations'
    ).catch(handleError(`Failed to get relations`, [], opts))
}

function buildRelation(r: RawRelation): Relation | undefined {
    const rel: Relation = {
        name: r.CONSTRAINT_NAME,
        origin: undefined, // 'fk' when not specified
        src: {schema: r.TABLE_OWNER, entity: r.TABLE_NAME, attrs: r.TABLE_COLUMNS.split(',').map(attributePathFromId)},
        ref: {schema: r.TARGET_OWNER, entity: r.TARGET_TABLE, attrs: r.TARGET_COLUMNS.split(',').map(attributePathFromId)},
        polymorphic: undefined,
        doc: undefined,
        extra: undefined,
    }
    // don't keep relation if columns are not found :/
    // should not happen if errors are not skipped
    return rel.src.attrs.length > 0 ? removeUndefined(rel) : undefined
}

export type RawType = {
    TYPE_OWNER: string
    TYPE_NAME: string
    TYPE_KIND: 'OBJECT' | 'COLLECTION' | 'ANYTYPE' | 'ANYDATA'
    ATTR_NAMES: string | null // comma separated list of column names
    ATTR_TYPES: string | null // comma separated list of column types
    ATTR_TYPE_LENS: string | null // comma separated list of column type lengths
    DEFINITION: string
}

export const getTypes = (opts: ScopeOpts) => async (conn: Conn): Promise<RawType[]> => {
    // https://docs.oracle.com/en/database/oracle/oracle-database/23/refrn/ALL_TYPES.html
    // https://docs.oracle.com/en/database/oracle/oracle-database/23/refrn/ALL_TYPE_ATTRS.html
    // https://docs.oracle.com/en/database/oracle/oracle-database/23/refrn/ALL_SOURCE.html
    // /!\ LISTAGG functions can product "ORA-01489: result of string concatenation is too long", mostly on DEFINITION column
    return conn.query<RawType>(`
        SELECT t.OWNER                                                                AS TYPE_OWNER
             , t.TYPE_NAME                                                            AS TYPE_NAME
             , t.TYPECODE                                                             AS TYPE_KIND
             , LISTAGG(a.ATTR_NAME, ',') WITHIN GROUP (ORDER BY a.ATTR_NO)            AS ATTR_NAMES
             , LISTAGG(a.ATTR_TYPE_NAME, ',') WITHIN GROUP (ORDER BY a.ATTR_NO)       AS ATTR_TYPES
             , LISTAGG(a.LENGTH, ',') WITHIN GROUP (ORDER BY a.ATTR_NO)               AS ATTR_TYPE_LENS
             , (SELECT LISTAGG(s.TEXT) WITHIN GROUP (ORDER BY s.LINE)
                FROM ALL_SOURCE s
                WHERE s.OWNER = t.OWNER AND s.NAME = t.TYPE_NAME AND s.TYPE = 'TYPE') AS DEFINITION
        FROM ALL_TYPES t
                 LEFT JOIN ALL_TYPE_ATTRS a ON a.OWNER = t.OWNER AND a.TYPE_NAME = t.TYPE_NAME
        WHERE ${scopeWhere({schema: 't.OWNER'}, opts)}
        GROUP BY t.OWNER, t.TYPE_NAME, t.TYPECODE, t.ATTRIBUTES`, [], 'getTypes'
    ).catch(handleError(`Failed to get types`, [], {...opts, ignoreErrors: true}))
}

function buildType(t: RawType): Type {
    return removeUndefined({
        schema: t.TYPE_OWNER,
        name: t.TYPE_NAME,
        values: undefined,
        attrs: t.ATTR_NAMES && t.ATTR_TYPES ? zip(
            t.ATTR_NAMES.split(','),
            t.ATTR_TYPES.split(',')
        ).map(([name, type]) => ({name, type})) : undefined,
        definition: t.DEFINITION
            .replaceAll(/TYPE [^ ]+ AS /gi, '')
            .replaceAll(/ALTER TYPE [^ ]+ /gi, '')
            .replaceAll(/[\n\r\s]+/gi, ' ')
            .replaceAll(/\( /g, '(')
            .replaceAll(/ \)/g, ')'),
        doc: undefined,
        extra: undefined,
    })
}

const getJsonColumns = (columns: Record<EntityId, RawColumn[]>, opts: ConnectorSchemaOpts) => async (conn: Conn): Promise<Record<EntityId, Record<AttributeName, ValueSchema>>> => {
    opts.logger.log('Inferring JSON columns ...')
    return mapEntriesAsync(columns, (entityId, tableCols) => {
        const ref = entityRefFromId(entityId)
        const jsonCols = tableCols.filter(c => c.COLUMN_TYPE === 'JSON')
        return mapValuesAsync(
            Object.fromEntries(jsonCols.map(c => [c.COLUMN_NAME, c.COLUMN_NAME])),
            c => getSampleValues(ref, [c], opts)(conn).then(valuesToSchema)
        )
    })
}

export const getSampleValues = (ref: EntityRef, attribute: AttributePath, opts: ConnectorSchemaOpts) => async (conn: Conn): Promise<AttributeValue[]> => {
    const sqlTable = buildSqlTable(ref)
    const sqlColumn = buildSqlColumn(attribute)
    const sampleSize = opts.sampleSize || connectorSchemaOptsDefaults.sampleSize
    return conn.query<{VALUE: AttributeValue}>(`
        SELECT ${sqlColumn} AS VALUE
        FROM ${sqlTable}
        WHERE ${sqlColumn} IS NOT NULL FETCH FIRST ${sampleSize} ROWS ONLY`, [], 'getSampleValues'
    ).then(rows => rows.map(row => row.VALUE))
        .catch(handleError(`Failed to get sample values for '${attributeRefToId({...ref, attribute})}'`, [], opts))
}

const getPolyColumns = (columns: Record<EntityId, RawColumn[]>, opts: ConnectorSchemaOpts) => async (conn: Conn): Promise<Record<EntityId, Record<AttributeName, string[]>>> => {
    opts.logger.log('Inferring polymorphic relations ...')
    return mapEntriesAsync(columns, (entityId, tableCols) => {
        const ref = entityRefFromId(entityId)
        const colNames = tableCols.map(c => c.COLUMN_NAME)
        const polyCols = tableCols.filter(c => isPolymorphic(c.COLUMN_NAME, colNames))
        return mapValuesAsync(
            Object.fromEntries(polyCols.map(c => [c.COLUMN_NAME, c.COLUMN_NAME])),
            c => getDistinctValues(ref, [c], opts)(conn).then(values => values.filter((v): v is string => typeof v === 'string'))
        )
    })
}

export const getDistinctValues = (ref: EntityRef, attribute: AttributePath, opts: ConnectorSchemaOpts) => async (conn: Conn): Promise<AttributeValue[]> => {
    const sqlTable = buildSqlTable(ref)
    const sqlColumn = buildSqlColumn(attribute)
    const sampleSize = opts.sampleSize || connectorSchemaOptsDefaults.sampleSize
    return conn.query<{ VALUE: AttributeValue }>(`
        SELECT DISTINCT ${sqlColumn} AS VALUE
        FROM ${sqlTable}
        WHERE ${sqlColumn} IS NOT NULL
        ORDER BY value FETCH FIRST ${sampleSize} ROWS ONLY`, [], 'getDistinctValues'
    ).then(rows => rows.map(row => row.VALUE), handleError(`Failed to get distinct values for '${attributeRefToId({...ref, attribute})}'`, [], opts))
}

const getTableColumns = (schema: string | undefined, table: string, opts: ConnectorSchemaOpts) => async (conn: Conn): Promise<string[]> => {
    const query = `SELECT COLUMN_NAME AS ATTR FROM ALL_TAB_COLS WHERE TABLE_NAME = :0${schema ? ` AND OWNER = :1` : ''};`
    return conn.query<{ ATTR: string }>(query, schema ? [table, schema] : [table], 'getTableColumns')
        .then(res => res.map(r => r.ATTR), handleError(`Failed to get table columns`, [], opts))
}
