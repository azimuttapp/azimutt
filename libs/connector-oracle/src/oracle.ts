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
        entities: tables
            .map(table => [toEntityId(table), table] as const)
            .map(([id, table]) => buildTableEntity(
                blockSize,
                table,
                columnsByTable[id] || [],
                columnsByIndex[id] || {},
                constraintsByTable[id] || [],
                indexesByTable[id] || [],
                jsonColumns[id] || {},
                polyColumns[id] || {}
            )).concat(views.map(view => buildViewEntity(view))),
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

const toEntityId = <T extends { TABLE_SCHEMA: string | null; TABLE_NAME: string }>(value: T): EntityId => entityRefToId({schema: value.TABLE_SCHEMA || undefined, entity: value.TABLE_NAME})
const groupByEntity = <T extends { TABLE_SCHEMA: string; TABLE_NAME: string }>(values: T[]): Record<EntityId, T[]> => groupBy(values, toEntityId)

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
    ANALYZE_LAST: Date | null
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
             , t.LAST_ANALYZED      AS ANALYZE_LAST
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
        WHERE ${scopeWhere({catalog: 'CLUSTER_NAME', schema: 'TABLESPACE_NAME', entity: 'TABLE_NAME'}, opts)}`, [], 'getTables'
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
            analyzeLast: table.ANALYZE_LAST?.toISOString(),
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

// FIXME: looks like materialized views are also in ALL_ALL_TABLES but can't differentiate them from real tables :/
export const getViews = (opts: ConnectorSchemaOpts) => async (conn: Conn): Promise<RawView[]> => {
    // https://docs.oracle.com/en/database/oracle/oracle-database/23/refrn/ALL_VIEWS.html
    // https://docs.oracle.com/en/database/oracle/oracle-database/23/refrn/ALL_TAB_COMMENTS.html
    // https://docs.oracle.com/en/database/oracle/oracle-database/23/refrn/ALL_MVIEWS.html
    // https://docs.oracle.com/en/database/oracle/oracle-database/23/refrn/ALL_MVIEW_COMMENTS.html
    return conn.query<RawView>(`
        SELECT v.OWNER     AS TABLE_OWNER
             , v.VIEW_NAME AS TABLE_NAME
             , v.TEXT      AS TABLE_DEFINITION
             , c.COMMENTS  AS TABLE_COMMENT
        FROM ALL_VIEWS v
                 LEFT JOIN ALL_TAB_COMMENTS c ON c.OWNER = v.OWNER AND c.TABLE_NAME = v.VIEW_NAME AND c.TABLE_TYPE = 'VIEW'
        WHERE v.OWNER NOT IN ('AUDSYS', 'CTXSYS', 'DBSNMP', 'DVSYS', 'GSMADMIN_INTERNAL', 'LBACSYS', 'MDSYS', 'OLAPSYS', 'SYS', 'SYSTEM', 'WMSYS', 'XDB')`, [], 'getViews'
    ).catch(handleError(`Failed to get views`, [], opts))
}

// FIXME: add columns (at least ^^)
function buildViewEntity(view: RawView): Entity {
    return {
        name: view.TABLE_NAME,
        kind: 'view',
        def: view.TABLE_DEFINITION,
        attrs: [], // TODO
        pk: undefined, // TODO
        indexes: [], // TODO
        checks: [], // TODO
        doc: view.TABLE_COMMENT || undefined,
        stats: undefined, // TODO
        extra: undefined,
    }
}

export type RawColumn = {
    COLUMN_INDEX: number
    TABLE_SCHEMA: string
    TABLE_NAME: string
    COLUMN_NAME: string
    COLUMN_TYPE: string
    COLUMN_TYPE_LEN: number
    COLUMN_NULLABLE: 'Y' | 'N'
}

export const getColumns = (opts: ConnectorSchemaOpts) => async (conn: Conn): Promise<RawColumn[]> => {
    // https://docs.oracle.com/en/database/oracle/oracle-database/23/refrn/DBA_TAB_COLUMNS.html
    return conn.query<RawColumn>(`
        SELECT column_id   AS COLUMN_INDEX,
               owner       AS TABLE_SCHEMA,
               table_name  AS TABLE_NAME,
               column_name AS COLUMN_NAME,
               data_type   AS COLUMN_TYPE,
               data_length AS COLUMN_TYPE_LEN,
               nullable    AS COLUMN_NULLABLE
        from sys.dba_tab_columns`, [], 'getColumns'
    ).catch(handleError(`Failed to get columns`, [], opts))
}

function buildAttribute(c: RawColumn, jsonColumn: ValueSchema | undefined): Attribute {
    return removeEmpty({
        name: c.COLUMN_NAME,
        type: c.COLUMN_TYPE,
        null: c.COLUMN_NULLABLE == 'Y' || undefined,
        attrs: jsonColumn ? schemaToAttributes(jsonColumn) : undefined,
    })
}

type RawConstraint = {
    TABLE_SCHEMA: string
    TABLE_NAME: string
    COLUMN_NAME: string
    CONSTRAINT_NAME: string
    CONSTRAINT_TYPE: 'P' | 'C' // P: primary key, C: Check,
    DEFERRABLE: 'DEFERRABLE' | 'NOT DEFERRABLE'
}

export const getConstraints = (opts: ConnectorSchemaOpts) => async (conn: Conn): Promise<RawConstraint[]> => {
    // https://docs.oracle.com/en/database/oracle/oracle-database/23/refrn/ALL_CONSTRAINTS.html
    // `constraint_type IN ('P', 'C')`: get only primary key and check constraints
    return conn.query<RawConstraint>(`
        SELECT uc.owner           AS TABLE_SCHEMA,
               uc.table_name      AS TABLE_NAME,
               acc.COLUMN_NAME    AS COLUMN_NAME,
               uc.constraint_name AS CONSTRAINT_NAME,
               uc.constraint_type AS CONSTRAINT_TYPE,
               uc.DEFERRABLE      AS DEFERRABLE
        FROM user_constraints uc
                 JOIN all_cons_columns acc ON uc.CONSTRAINT_NAME = acc.CONSTRAINT_NAME
        WHERE CONSTRAINT_TYPE IN ('P', 'C')
        ORDER BY TABLE_SCHEMA, TABLE_NAME, CONSTRAINT_NAME`, [], 'getConstraints'
    ).catch(handleError(`Failed to get constraints`, [], opts))
}

function buildPrimaryKey(c: RawConstraint, columns: { [i: number]: string }): PrimaryKey {
    return removeUndefined({
        name: c.CONSTRAINT_NAME,
        attrs: [[c.COLUMN_NAME]],
    })
}

function buildCheck(c: RawConstraint, columns: { [i: number]: string }): Check {
    return removeUndefined({
        name: c.CONSTRAINT_NAME,
        attrs: [[c.COLUMN_NAME]],
        predicate: '',
    })
}

type RawIndex = {
    TABLE_SCHEMA: string
    TABLE_NAME: string
    INDEX_NAME: string
    COLUMNS: string // comma separated list of columns
    IS_UNIQUE: 'UNIQUE' | 'NONUNIQUE'
}

export const getIndexes = (opts: ConnectorSchemaOpts) => async (conn: Conn): Promise<RawIndex[]> => {
    // https://docs.oracle.com/en/database/oracle/oracle-database/23/refrn/ALL_INDEXES.html
    // https://docs.oracle.com/en/database/oracle/oracle-database/23/refrn/ALL_IND_COLUMNS.html
    return conn.query<RawIndex>(`
        SELECT idx.table_owner                                                           AS TABLE_SCHEMA
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
