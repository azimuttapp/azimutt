import {
    groupBy,
    mapEntriesAsync,
    mapValues,
    mapValuesAsync,
    pluralize,
    pluralizeL,
    removeEmpty,
    removeUndefined,
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
    valuesToSchema,
} from "@azimutt/models";
import {buildSqlColumn, buildSqlTable, scopeWhere} from "./helpers";
import {Conn} from "./connect";

export const getSchema = (opts: ConnectorSchemaOpts) => async (conn: Conn): Promise<Database> => {
    const start = Date.now()
    const scope = formatConnectorScope({schema: 'schema', entity: 'table'}, opts)
    opts.logger.log(`Connected to the database${scope ? `, exporting for ${scope}` : ''} ...`)

    // access system tables only
    const blockSize: number = await getBlockSize(opts)(conn)
    const database: RawDatabase = await getDatabase(opts)(conn)
    const tables: RawTable[] = await getTables(opts)(conn)
    const views: RawView[] = await getViews(opts)(conn)
    opts.logger.log(`Found ${pluralize(tables.length + views.length, 'table')} ...`)
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
    const columnsByIndex: Record<EntityId, { [i: number]: string }> = mapValues(columnsByTable, cols => cols.reduce((acc, col) => ({...acc, [col.COLUMN_INDEX]: col.COLUMN_NAME}), {}))
    const constraintsByTable = groupByEntity(constraints)
    const indexesByTable = groupByEntity(indexes)
    opts.logger.log(`✔︎ Exported ${pluralizeL(tables, 'table')}, ${pluralizeL(relations, 'relation')} and ${pluralizeL(types, 'type')} from the database!`)
    return removeUndefined({
        entities: tables.map(table => [toEntityId(table), table] as const).map(([id, table]) => buildTableEntity(
            blockSize,
            table,
            columnsByTable[id] || [],
            columnsByIndex[id] || {},
            constraintsByTable[id] || [],
            indexesByTable[id] || [],
            jsonColumns[id] || {},
            polyColumns[id] || {}
        )).concat(views.map(view => [toEntityId(view), view] as const).map(([id, view]) => buildViewEntity(
            view,
            columnsByTable[id] || [],
            jsonColumns[id] || {}
        ))),
        relations: relations
            .map(r => buildRelation(r, columnsByIndex))
            .filter((rel): rel is Relation => !!rel),
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

const toEntityId = <T extends { TABLE_OWNER: string; TABLE_NAME: string }>(value: T): EntityId => entityRefToId({schema: value.TABLE_OWNER, entity: value.TABLE_NAME})
const groupByEntity = <T extends { TABLE_OWNER: string; TABLE_NAME: string }>(values: T[]): Record<EntityId, T[]> => groupBy(values, toEntityId)

export type RawDatabase = {
    version: string
    database: string
    blks_read: number
}

export const getDatabase = (opts: ConnectorSchemaOpts) => async (conn: Conn): Promise<RawDatabase> => {
    const data: RawDatabase = {version: '', database: '', blks_read: 0}

    await conn.query(`SELECT BANNER FROM V$VERSION`).then(res => {
        data.version = res?.[0]?.[0] as string
    })

    await conn.query(`SELECT name FROM v$database`).then(res => {
        data.database = res?.[0]?.[0] as string
    })

    await conn.query(`select value from v$sysstat where name = 'physical reads'`).then(res => {
        data.blks_read = res?.[0]?.[0] ? Number(res[0][0]) : 0
    })

    return data
}

export const getBlockSize = (opts: ConnectorSchemaOpts) => async (conn: Conn): Promise<number> => {
    return conn.query(`select distinct bytes / blocks AS block_size from user_segments`, [], 'getBlockSize')
        .then(res => (res?.[0]?.[0] ? Number(res[0][0]) : 8192))
        .catch(handleError(`Failed to get block size`, 0, opts))
}

export type RawTable = {
    TABLE_OWNER: string
    TABLE_CLUSTER: string | null
    TABLE_SCHEMA: string | null
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

export const getTables = (opts: ConnectorSchemaOpts) => async (conn: Conn): Promise<RawTable[]> => {
    // https://docs.oracle.com/en/database/oracle/oracle-database/23/refrn/ALL_ALL_TABLES.html
    // https://docs.oracle.com/en/database/oracle/oracle-database/23/refrn/ALL_TAB_COMMENTS.html
    // https://docs.oracle.com/en/database/oracle/oracle-database/23/refrn/ALL_MVIEWS.html
    // https://docs.oracle.com/en/database/oracle/oracle-database/23/refrn/ALL_MVIEW_COMMENTS.html
    return conn.query<RawTable>(`
        SELECT t.OWNER              AS TABLE_OWNER
             , t.CLUSTER_NAME       AS TABLE_CLUSTER
             , t.TABLESPACE_NAME    AS TABLE_SCHEMA
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

function buildTableEntity(blockSize: number, table: RawTable, columns: RawColumn[], columnsByIndex: { [i: number]: string }, constraints: RawConstraint[], indexes: RawIndex[], jsonColumns: Record<AttributeName, ValueSchema>, polyColumns: Record<AttributeName, string[]>): Entity {
    return {
        catalog: table.TABLE_CLUSTER || undefined,
        schema: table.TABLE_SCHEMA || undefined,
        name: table.TABLE_NAME,
        kind: table.MVIEW_DEFINITION ? 'materialized view' : undefined,
        def: table.MVIEW_DEFINITION || undefined,
        attrs: columns?.slice(0)
            ?.sort((a, b) => a.COLUMN_INDEX - b.COLUMN_INDEX)
            ?.map(c => buildAttribute(c, jsonColumns[c.COLUMN_NAME])) || [],
        pk: constraints
            .filter(c => c.CONSTRAINT_TYPE === 'P')
            .map(c => buildPrimaryKey(c, columnsByIndex))[0] || undefined,
        indexes: indexes.map(i => buildIndex(blockSize, i, columnsByIndex)),
        checks: constraints
            .filter(c => c.CONSTRAINT_TYPE === 'C')
            .map(c => buildCheck(c, columnsByIndex)),
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
        extra: undefined,
    }
}

export type RawView = {
    TABLE_OWNER: string
    TABLE_NAME: string
    TABLE_DEFINITION: string
    TABLE_COMMENT: string | null
}

export const getViews = (opts: ConnectorSchemaOpts) => async (conn: Conn): Promise<RawView[]> => {
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

function buildViewEntity(view: RawView, columns: RawColumn[], jsonColumns: Record<AttributeName, ValueSchema>): Entity {
    return {
        name: view.TABLE_NAME,
        kind: 'view',
        def: view.TABLE_DEFINITION,
        attrs: columns?.slice(0)
            ?.sort((a, b) => a.COLUMN_INDEX - b.COLUMN_INDEX)
            ?.map(c => buildAttribute(c, jsonColumns[c.COLUMN_NAME])) || [],
        pk: undefined, // TODO
        indexes: [], // TODO
        checks: [], // TODO
        doc: view.TABLE_COMMENT || undefined,
        stats: undefined, // TODO
        extra: undefined,
    }
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

export const getColumns = (opts: ConnectorSchemaOpts) => async (conn: Conn): Promise<RawColumn[]> => {
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

function buildAttribute(c: RawColumn, jsonColumn: ValueSchema | undefined): Attribute {
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
            distinctValues: undefined,
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
    COLUMN_NAMES: string
    COLUMN_POSITIONS: number | null
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

export const getConstraints = (opts: ConnectorSchemaOpts) => async (conn: Conn): Promise<RawConstraint[]> => {
    // https://docs.oracle.com/en/database/oracle/oracle-database/23/refrn/ALL_CONSTRAINTS.html
    // https://docs.oracle.com/en/database/oracle/oracle-database/23/refrn/ALL_CONS_COLUMNS.html
    // `constraint_type IN ('P', 'C')`: get only primary key and check constraints
    return conn.query<RawConstraint>(`
        SELECT c.CONSTRAINT_NAME            AS CONSTRAINT_NAME
             , c.CONSTRAINT_TYPE            AS CONSTRAINT_TYPE
             , c.OWNER                      AS TABLE_OWNER
             , c.TABLE_NAME                 AS TABLE_NAME
             , LISTAGG(cc.COLUMN_NAME, ',') AS COLUMN_NAMES
             , LISTAGG(cc.POSITION, ',')    AS COLUMN_POSITIONS
             , MIN(c.SEARCH_CONDITION_VC)   AS PREDICATE
             , MIN(c.R_OWNER)               AS REF_OWNER
             , MIN(c.R_CONSTRAINT_NAME)     AS REF_CONSTRAINT
             , MIN(c.STATUS)                AS STATUS
             , MIN(c.DEFERRABLE)            AS DEFERRABLE
             , MIN(c.DEFERRED)              AS DEFERRED
             , MIN(c.VALIDATED)             AS VALIDATED
             , MIN(c.INVALID)               AS INVALID
             , MIN(c.GENERATED)             AS GENERATED
             , MIN(c.LAST_CHANGE)           AS LAST_CHANGE
             , MIN(c.INDEX_OWNER)           AS INDEX_OWNER
             , MIN(c.INDEX_NAME)            AS INDEX_NAME
        FROM ALL_CONSTRAINTS c
                 JOIN ALL_CONS_COLUMNS cc ON cc.OWNER = c.OWNER AND cc.TABLE_NAME = c.TABLE_NAME AND cc.CONSTRAINT_NAME = c.CONSTRAINT_NAME
        WHERE c.CONSTRAINT_TYPE IN ('P', 'C') AND (c.SEARCH_CONDITION_VC IS NULL OR c.SEARCH_CONDITION_VC NOT LIKE '% IS NOT NULL') AND ${scopeWhere({schema: 'c.OWNER', entity: 'c.TABLE_NAME'}, opts)}
        GROUP BY c.CONSTRAINT_NAME, c.CONSTRAINT_TYPE, c.OWNER, c.TABLE_NAME`, [], 'getConstraints'
    ).catch(handleError(`Failed to get constraints`, [], opts))
}

function buildPrimaryKey(c: RawConstraint, columns: { [i: number]: string }): PrimaryKey {
    return removeUndefined({
        name: c.CONSTRAINT_NAME,
        attrs: c.COLUMN_NAMES.split(',').map(name => [name]),
        doc: undefined, // no constraint comment in Oracle
        stats: undefined,
        extra: undefined,
    })
}

function buildCheck(c: RawConstraint, columns: { [i: number]: string }): Check {
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
    TABLE_OWNER: string
    TABLE_NAME: string
    INDEX_NAME: string
    COLUMNS: string // comma separated list of columns
    IS_UNIQUE: 'UNIQUE' | 'NONUNIQUE'
}

export const getIndexes = (opts: ConnectorSchemaOpts) => async (conn: Conn): Promise<RawIndex[]> => {
    // https://docs.oracle.com/en/database/oracle/oracle-database/23/refrn/ALL_INDEXES.html
    // https://docs.oracle.com/en/database/oracle/oracle-database/23/refrn/ALL_IND_COLUMNS.html
    return conn.query<RawIndex>(`
        SELECT idx.table_owner                                                           AS TABLE_OWNER
             , idx.table_name                                                            AS TABLE_NAME
             , idx.index_name                                                            AS INDEX_NAME
             , LISTAGG(col.column_name, ',') WITHIN GROUP (ORDER BY col.column_position) AS COLUMNS
             , idx.uniqueness                                                            AS IS_UNIQUE
        FROM ALL_INDEXES idx
                 JOIN ALL_IND_COLUMNS col ON idx.index_name = col.index_name AND idx.table_owner = col.table_owner AND idx.table_name = col.table_name
        GROUP BY idx.index_name, idx.table_owner, idx.table_name, idx.uniqueness`, [], 'getIndexes'
    ).catch(handleError(`Failed to get indexes`, [], opts))
}

function buildIndex(blockSize: number, index: RawIndex, columns: { [i: number]: string }): Index {
    return removeUndefined({
        name: index.INDEX_NAME,
        attrs: [index.COLUMNS.split(',')],
        unique: index.IS_UNIQUE === 'UNIQUE' || undefined,
    })
}

type RawRelation = {
    constraint_name: string
    table_schema: string
    table_name: string
    table_column: string
    target_schema: string
    target_table: string
    target_column: string
    is_deferrable: 'DEFERRABLE' | 'NOT DEFERRABLE'
    on_delete: string
}

export const getRelations = (opts: ConnectorSchemaOpts) => async (conn: Conn): Promise<RawRelation[]> => {
    return conn.query<RawRelation>(`
        SELECT a.constraint_name,
               a.owner        AS table_schema,
               a.table_name   AS table_name,
               ac.column_name AS table_column,
               cc.owner       AS target_schema,
               cc.table_name  AS target_table,
               cc.column_name AS target_column,
               a.deferrable   AS is_deferable,
               a.delete_rule  AS on_delete_action
        FROM all_constraints a
                 JOIN all_cons_columns ac ON a.constraint_name = ac.constraint_name AND a.owner = ac.owner
                 JOIN all_constraints c ON a.r_constraint_name = c.constraint_name AND a.r_owner = c.owner
                 JOIN all_cons_columns cc ON c.constraint_name = cc.constraint_name AND c.owner = cc.owner AND ac.position = cc.position
        WHERE a.constraint_type = 'R'
        ORDER BY a.table_name, a.constraint_name, ac.position`, [], 'getRelations'
    ).catch(handleError(`Failed to get relations`, [], opts))
}

function buildRelation(r: RawRelation, columnsByIndex: Record<EntityId, { [i: number]: string }>): Relation | undefined {
    const src = {schema: r.table_schema, entity: r.table_name}
    const ref = {schema: r.target_schema, entity: r.target_table}
    const rel: Relation = {
        name: r.constraint_name,
        kind: undefined, // 'many-to-one' when not specified
        origin: undefined, // 'fk' when not specified
        src,
        ref,
        attrs: [{src: [r.table_column], ref: [r.target_column]}]
    }
    // don't keep relation if columns are not found :/
    // should not happen if errors are not skipped
    return rel.attrs.length > 0 ? removeUndefined(rel) : undefined
}

export type RawType = {
    type_schema: string
    type_name: string
}

export const getTypes = (opts: ConnectorSchemaOpts) => async (conn: Conn): Promise<RawType[]> => {
    return conn.query<RawType>(`
        SELECT t.owner AS type_schema,
               t.type_name
        FROM all_types t
        WHERE t.owner IS NOT NULL
        ORDER BY type_schema, type_name`, [], 'getTypes'
    ).catch(handleError(`Failed to get types`, [], opts))
}

function buildType(t: RawType): Type {
    return removeUndefined({
        schema: t.type_schema,
        name: t.type_name,
    })
}

const getJsonColumns = (columns: Record<EntityId, RawColumn[]>, opts: ConnectorSchemaOpts) => async (conn: Conn): Promise<Record<EntityId, Record<AttributeName, ValueSchema>>> => {
    opts.logger.log('Inferring JSON columns ...')
    return mapEntriesAsync(columns, (entityId, tableCols) => {
        const ref = entityRefFromId(entityId)
        const jsonCols = tableCols.filter(c => c.COLUMN_TYPE === 'jsonb')
        return mapValuesAsync(
            Object.fromEntries(jsonCols.map(c => [c.COLUMN_NAME, c.COLUMN_NAME])),
            c => getSampleValues(ref, [c], opts)(conn).then(valuesToSchema)
        )
    })
}

const getSampleValues = (ref: EntityRef, attribute: AttributePath, opts: ConnectorSchemaOpts) => async (conn: Conn): Promise<AttributeValue[]> => {
    const sqlTable = buildSqlTable(ref)
    const sqlColumn = buildSqlColumn(attribute)
    const sampleSize = opts.sampleSize || connectorSchemaOptsDefaults.sampleSize
    return conn.query<{value: AttributeValue}>(`
        SELECT ${sqlColumn} AS value
        FROM ${sqlTable}
        WHERE ${sqlColumn} IS NOT NULL FETCH FIRST ${sampleSize} ROWS ONLY`, [], 'getSampleValues'
    ).then(rows => rows.map(row => row.value))
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
    return conn.query<{ value: AttributeValue }>(`
        SELECT DISTINCT ${sqlColumn} AS value
        FROM ${sqlTable}
        WHERE ${sqlColumn} IS NOT NULL
        ORDER BY value FETCH FIRST ${sampleSize} ROWS ONLY`, [], 'getDistinctValues'
    ).then(rows => rows.map(row => row.value))
        .catch(err => err instanceof Error && err.message.match(/materialized view "[^"]+" has not been populated/) ? [] : Promise.reject(err))
        .catch(handleError(`Failed to get distinct values for '${attributeRefToId({...ref, attribute})}'`, [], opts))
}
