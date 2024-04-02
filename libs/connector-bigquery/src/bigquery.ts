import {BigQueryTimestamp, Dataset, DatasetsResponse} from "@google-cloud/bigquery";
import {groupBy, joinLimit, pluralizeL, removeEmpty, removeUndefined, sequence, zip} from "@azimutt/utils";
import {
    Attribute,
    ConnectorSchemaOpts,
    Database,
    Entity,
    EntityId,
    formatConnectorScope,
    formatEntityRef,
    handleError,
    Index,
    PrimaryKey,
    Relation,
    SchemaName
} from "@azimutt/database-model";
import {removeQuotes, scopeFilter, scopeWhere} from "./helpers";
import {Conn} from "./connect";

export const getSchema = (opts: ConnectorSchemaOpts) => async (conn: Conn): Promise<Database> => {
    opts.logger.log('Connected to the database ...')
    const projectId = opts.catalog || await conn.underlying.getProjectId()
    const scope = formatConnectorScope({schema: 'dataset', entity: 'table'}, opts)
    opts.logger.log(`Exporting project '${projectId}'${scope ? `, only for ${scope}` : ''} ...`)
    const datasetIds = await getDatasets(projectId, opts)(conn)
    opts.logger.log(`Found ${pluralizeL(datasetIds, 'dataset')} to export (${joinLimit(datasetIds)}) ...`)
    const datasetDbs: Database[] = await sequence(datasetIds, async datasetId => {
        opts.logger.log(`Exporting dataset '${projectId}.${datasetId}' ...`)

        // access system tables only
        const tables = await getTables(projectId, datasetId, opts)(conn)
        opts.logger.log(`  Found ${pluralizeL(tables, 'table')} ...`)
        const columns = await getColumns(projectId, datasetId, opts)(conn)
        opts.logger.log(`  Found ${pluralizeL(columns, 'column')} ...`)
        const primaryKeys = await getPrimaryKeys(projectId, datasetId, opts)(conn)
        opts.logger.log(`  Found ${pluralizeL(primaryKeys, 'primary key')} ...`)
        const indexes = await getIndexes(projectId, datasetId, opts)(conn)
        opts.logger.log(`  Found ${pluralizeL(indexes, 'index')} ...`)
        const foreignKeys = await getForeignKeys(projectId, datasetId, opts)(conn)
        opts.logger.log(`  Found ${pluralizeL(foreignKeys, 'foreign key')} ...`)

        // access table data when options are requested
        // TODO: JSON columns, polymorphic relations, pii, join relations...

        // build the database
        const columnsByTable = groupByEntity(columns)
        const primaryKeysByTable = groupByEntity(primaryKeys)
        const indexesByTable = groupByEntity(indexes)
        return {
            entities: tables.map(table => [toEntityId(table), table] as const).map(([id, table]) => buildEntity(
                table,
                columnsByTable[id] || [],
                primaryKeysByTable[id] || [],
                indexesByTable[id] || []
            )),
            relations: foreignKeys.map(buildRelation)
        }
    })

    const entities = datasetDbs.flatMap(s => s.entities || [])
    const relations = datasetDbs.flatMap(s => s.relations || [])
    opts.logger.log(`✔︎ Exported ${pluralizeL(entities, 'table')} and ${pluralizeL(relations, 'relation')} from the database!`)
    return Database.parse(removeEmpty({
        entities,
        relations,
        types: undefined,
        doc: undefined,
        stats: undefined,
        extra: undefined,
    }))
}

// 👇️ Private functions, some are exported only for tests
// If you use them, beware of breaking changes!

const toEntityId = <T extends { table_catalog: string, table_schema: string, table_name: string }>(value: T): EntityId => formatEntityRef({catalog: value.table_catalog, schema: value.table_schema, entity: value.table_name})
const groupByEntity = <T extends { table_catalog: string, table_schema: string, table_name: string }>(values: T[]): Record<EntityId, T[]> => groupBy(values, toEntityId)

export const getDatasets = (projectId: string, opts: ConnectorSchemaOpts) => async (conn: Conn): Promise<SchemaName[]> => {
    const datasets: Dataset[] = await conn.underlying.getDatasets({projectId}).then(([datasets]: DatasetsResponse) => datasets)
    return datasets.map(d => d.id).filter((id: string | undefined): id is string => !!id).filter(id => scopeFilter({schema: id}, opts))
}

export type RawTable = {
    table_catalog: string
    table_schema: string
    table_name: string
    table_type: 'BASE TABLE' | 'VIEW' | 'MATERIALIZED VIEW' | 'EXTERNAL' | 'CLONE' | 'SNAPSHOT'
    ddl: string
    creation_time: BigQueryTimestamp
    view_definition: string | null
    last_refresh_time: BigQueryTimestamp | null
    description: string | null
    labels: string | null // ex: [STRUCT("key1", "value1"), STRUCT("key2", "value2")]
    partitions: string[]
    rows: number | null
    bytes: number | null
    last_modified: BigQueryTimestamp | null
}

export const getTables = (projectId: string, datasetId: string, opts: ConnectorSchemaOpts) => async (conn: Conn): Promise<RawTable[]> => {
    // https://cloud.google.com/bigquery/docs/information-schema-tables
    // https://cloud.google.com/bigquery/docs/information-schema-partitions
    // https://cloud.google.com/bigquery/docs/information-schema-views
    // https://cloud.google.com/bigquery/docs/information-schema-materialized-views
    // https://cloud.google.com/bigquery/docs/information-schema-table-options
    return conn.query<RawTable>(`
        SELECT t.table_catalog
             , t.table_schema
             , t.table_name
             , t.table_type
             , t.ddl
             , t.creation_time
             , v.view_definition
             , m.last_refresh_time
             , d.option_value                         AS description
             , l.option_value                         AS labels
             , ARRAY_AGG(p.partition_id IGNORE NULLS) AS partitions
             , SUM(p.total_rows)                      AS \`rows\`
             , SUM(p.total_billable_bytes)            AS bytes
             , MAX(p.last_modified_time)              AS last_modified
        FROM ${projectId}.${datasetId}.INFORMATION_SCHEMA.TABLES t
                 LEFT JOIN ${projectId}.${datasetId}.INFORMATION_SCHEMA.PARTITIONS p ON p.table_catalog = t.table_catalog AND p.table_schema = t.table_schema AND p.table_name = t.table_name
                 LEFT JOIN ${projectId}.${datasetId}.INFORMATION_SCHEMA.VIEWS v ON v.table_catalog = t.table_catalog AND v.table_schema = t.table_schema AND v.table_name = t.table_name
                 LEFT JOIN ${projectId}.${datasetId}.INFORMATION_SCHEMA.MATERIALIZED_VIEWS m ON m.table_catalog = t.table_catalog AND m.table_schema = t.table_schema AND m.table_name = t.table_name
                 LEFT JOIN ${projectId}.${datasetId}.INFORMATION_SCHEMA.TABLE_OPTIONS d ON d.table_catalog = t.table_catalog AND d.table_schema = t.table_schema AND d.table_name = t.table_name AND d.option_name = 'description'
                 LEFT JOIN ${projectId}.${datasetId}.INFORMATION_SCHEMA.TABLE_OPTIONS l ON l.table_catalog = t.table_catalog AND l.table_schema = t.table_schema AND l.table_name = t.table_name AND l.option_name = 'labels'
        WHERE t.table_type IN ('BASE TABLE', 'VIEW', 'MATERIALIZED VIEW')${scopeWhere(' AND ', {catalog: 't.table_catalog', schema: 't.table_schema', entity: 't.table_name'}, opts)}
        GROUP BY t.table_catalog, t.table_schema, t.table_name, t.table_type, t.ddl, t.creation_time, v.view_definition, m.last_refresh_time, d.option_value, l.option_value
        ORDER BY t.table_catalog, t.table_schema, t.table_name;`, [], 'getTables'
    ).catch(handleError(`Failed to get tables for ${projectId}.${datasetId}`, [], opts))
}

function buildEntity(table: RawTable, columns: RawColumn[], primaryKeys: RawPrimaryKey[], indexes: RawIndex[]): Entity {
    const pk = primaryKeys[0]
    return Entity.parse(removeUndefined({
        catalog: table.table_catalog,
        schema: table.table_schema,
        name: table.table_name,
        kind: table.table_type === 'VIEW' ? 'view' as const : table.table_type === 'MATERIALIZED VIEW' ? 'materialized view' as const : undefined,
        def: table.view_definition || undefined,
        attrs: columns.slice(0)
            .sort((a, b) => a.column_index - b.column_index)
            .map(buildAttribute),
        pk: pk ? buildPrimaryKey(pk) : undefined,
        indexes: indexes.length > 0 ? indexes.map(buildIndex) : undefined,
        checks: undefined,
        doc: table.description ? removeQuotes(table.description) : undefined,
        stats: undefined,
        extra: undefined
    }))
}

export type RawColumn = {
    table_catalog: string
    table_schema: string
    table_name: string
    column_index: number
    column_name: string
    column_type: string // see https://cloud.google.com/bigquery/docs/reference/standard-sql/data-types
    column_default: string
    column_nullable: boolean
    column_partitioning: boolean
    description: string | null
}

export const getColumns = (projectId: string, datasetId: string, opts: ConnectorSchemaOpts) => async (conn: Conn): Promise<RawColumn[]> => {
    // https://cloud.google.com/bigquery/docs/information-schema-columns
    // https://cloud.google.com/bigquery/docs/information-schema-column-field-paths
    return conn.query<RawColumn>(`
        SELECT c.table_catalog
             , c.table_schema
             , c.table_name
             , c.ordinal_position               AS column_index
             , c.column_name
             , c.data_type                      AS column_type
             , c.column_default                 AS column_default
             , c.is_nullable = 'YES'            AS column_nullable
             , c.is_partitioning_column = 'YES' AS column_partitioning
             , p.description
        FROM ${projectId}.${datasetId}.INFORMATION_SCHEMA.COLUMNS c
                 JOIN ${projectId}.${datasetId}.INFORMATION_SCHEMA.COLUMN_FIELD_PATHS p ON p.table_catalog = c.table_catalog AND p.table_schema = c.table_schema AND p.table_name = c.table_name AND p.column_name = c.column_name
        WHERE c.ordinal_position IS NOT NULL${scopeWhere(' AND ', {catalog: 'c.table_catalog', schema: 'c.table_schema', entity: 'c.table_name'}, opts)}
        ORDER BY c.table_catalog, c.table_schema, c.table_name, c.ordinal_position;`, [], 'getColumns'
    ).catch(handleError(`Failed to get columns for ${projectId}.${datasetId}`, [], opts))
}

function buildAttribute(column: RawColumn): Attribute {
    return Attribute.parse(removeUndefined({
        name: column.column_name,
        type: column.column_type,
        nullable: column.column_nullable || undefined,
        generated: undefined,
        default: column.column_default !== 'NULL' ? column.column_default : undefined,
        values: undefined,
        attrs: undefined,
        doc: column.description || undefined,
        stats: undefined,
        extra: undefined
    }))
}

export type RawPrimaryKey = {
    constraint_catalog: string
    constraint_schema: string
    constraint_name: string
    constraint_type: string
    table_catalog: string
    table_schema: string
    table_name: string
    table_columns: string[]
}

export const getPrimaryKeys = (projectId: string, datasetId: string, opts: ConnectorSchemaOpts) => async (conn: Conn): Promise<RawPrimaryKey[]> => {
    // https://cloud.google.com/bigquery/docs/information-schema-table-constraints
    // https://cloud.google.com/bigquery/docs/information-schema-key-column-usage
    return conn.query<RawPrimaryKey>(`
        SELECT c.constraint_catalog
             , c.constraint_schema
             , c.constraint_name
             , MIN(c.constraint_type)                               AS constraint_type
             , MIN(f.table_catalog)                                 AS table_catalog
             , MIN(f.table_schema)                                  AS table_schema
             , MIN(f.table_name)                                    AS table_name
             , ARRAY_AGG(f.column_name ORDER BY f.ordinal_position) AS table_columns
        FROM ${projectId}.${datasetId}.INFORMATION_SCHEMA.TABLE_CONSTRAINTS c
                 JOIN ${projectId}.${datasetId}.INFORMATION_SCHEMA.KEY_COLUMN_USAGE f ON f.constraint_catalog = c.constraint_catalog AND f.constraint_schema = c.constraint_schema AND f.constraint_name = c.constraint_name
        WHERE c.constraint_type = 'PRIMARY KEY'${scopeWhere(' AND ', {catalog: 'c.table_catalog', schema: 'c.table_schema', entity: 'c.table_name'}, opts)}
        GROUP BY c.constraint_catalog, c.constraint_schema, c.constraint_name;`, [], 'getPrimaryKeys'
    ).catch(handleError(`Failed to get primary keys for ${projectId}.${datasetId}`, [], opts))
}

function buildPrimaryKey(pk: RawPrimaryKey): PrimaryKey {
    return PrimaryKey.parse(removeUndefined({
        name: pk.constraint_name,
        attrs: pk.table_columns.map(c => [c]),
        doc: undefined,
        stats: undefined,
        extra: undefined
    }))
}

export type RawForeignKey = {
    constraint_catalog: string
    constraint_schema: string
    constraint_name: string
    table_catalog: string
    table_schema: string
    table_name: string
    table_columns: string[]
    target_catalog: string
    target_schema: string
    target_name: string
    target_columns: string[]
}

export const getForeignKeys = (projectId: string, datasetId: string, opts: ConnectorSchemaOpts) => async (conn: Conn): Promise<RawForeignKey[]> => {
    // https://cloud.google.com/bigquery/docs/information-schema-table-constraints
    // https://cloud.google.com/bigquery/docs/information-schema-key-column-usage
    // https://cloud.google.com/bigquery/docs/information-schema-constraint-column-usage: get target column for foreign keys
    return conn.query<RawForeignKey>(`
        SELECT c.constraint_catalog
             , c.constraint_schema
             , c.constraint_name
             , MIN(f.table_catalog)              AS table_catalog
             , MIN(f.table_schema)               AS table_schema
             , MIN(f.table_name)                 AS table_name
             , ARRAY_AGG(distinct f.column_name) AS table_columns
             , MIN(t.table_catalog)              AS target_catalog
             , MIN(t.table_schema)               AS target_schema
             , MIN(t.table_name)                 AS target_name
             , ARRAY_AGG(distinct t.column_name) AS target_columns
        FROM ${projectId}.${datasetId}.INFORMATION_SCHEMA.TABLE_CONSTRAINTS c
                 JOIN ${projectId}.${datasetId}.INFORMATION_SCHEMA.KEY_COLUMN_USAGE f ON f.constraint_catalog = c.constraint_catalog AND f.constraint_schema = c.constraint_schema AND f.constraint_name = c.constraint_name
                 JOIN ${projectId}.${datasetId}.INFORMATION_SCHEMA.CONSTRAINT_COLUMN_USAGE t ON t.constraint_catalog = c.constraint_catalog AND t.constraint_schema = c.constraint_schema AND t.constraint_name = c.constraint_name
        WHERE c.constraint_type = 'FOREIGN KEY'${scopeWhere(' AND ', {catalog: 'c.table_catalog', schema: 'c.table_schema', entity: 'c.table_name'}, opts)}
        GROUP BY c.constraint_catalog, c.constraint_schema, c.constraint_name;`, [], 'getForeignKeys'
    ).catch(handleError(`Failed to get foreign keys for ${projectId}.${datasetId}`, [], opts))
}

function buildRelation(fk: RawForeignKey): Relation {
    return Relation.parse(removeUndefined({
        name: fk.constraint_name,
        kind: undefined,
        origin: undefined,
        src: { schema: fk.table_schema, entity: fk.table_name },
        ref: { schema: fk.target_schema, entity: fk.target_name },
        attrs: zip(fk.table_columns, fk.target_columns).map(([src, ref]) => ({src: [src], ref: [ref]})),
        polymorphic: undefined,
        doc: undefined,
        extra: undefined
    }))
}

export type RawIndex = {
    table_catalog: string
    table_schema: string
    table_name: string
    index_name: string
    index_columns: string[]
    index_status: string
    creation_time: BigQueryTimestamp
    last_modification_time: BigQueryTimestamp
    last_refresh_time: BigQueryTimestamp | null
    disable_reason: string | null
    ddl: string
    total_storage_bytes: number
}

export const getIndexes = (projectId: string, datasetId: string, opts: ConnectorSchemaOpts) => async (conn: Conn): Promise<RawIndex[]> => {
    // https://cloud.google.com/bigquery/docs/information-schema-indexes
    // https://cloud.google.com/bigquery/docs/information-schema-index-columns
    return conn.query<RawIndex>(`
        SELECT i.index_catalog               AS table_catalog
             , i.index_schema                AS table_schema
             , i.table_name
             , i.index_name
             , ARRAY_AGG(c.index_field_path) AS index_columns
             , i.index_status
             , i.creation_time
             , i.last_modification_time
             , i.last_refresh_time
             , i.disable_reason
             , i.ddl
             , i.total_storage_bytes
        FROM ${projectId}.${datasetId}.INFORMATION_SCHEMA.SEARCH_INDEXES i
                 JOIN ${projectId}.${datasetId}.INFORMATION_SCHEMA.SEARCH_INDEX_COLUMNS c ON c.index_catalog = i.index_catalog AND c.index_schema = i.index_schema AND c.table_name = i.table_name AND c.index_name = i.index_name
        ${scopeWhere('WHERE ', {catalog: 'i.index_catalog', schema: 'i.index_schema', entity: 'i.table_name'}, opts)}
        GROUP BY i.index_catalog, i.index_schema, i.table_name, i.index_name, i.index_status, i.creation_time, i.last_modification_time, i.last_refresh_time, i.disable_reason, i.ddl, i.total_storage_bytes;`, [], 'getIndexes'
    ).catch(handleError(`Failed to get indexes for ${projectId}.${datasetId}`, [], opts))
}

function buildIndex(index: RawIndex): Index {
    return Index.parse(removeUndefined({
        name: index.index_name,
        attrs: index.index_columns.map(c => [c]),
        unique: undefined,
        partial: undefined,
        definition: index.ddl,
        doc: undefined,
        stats: removeUndefined({
            size: index.total_storage_bytes,
            scans: undefined,
        }),
        extra: undefined
    }))
}
