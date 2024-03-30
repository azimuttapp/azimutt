import {BigQueryTimestamp, Dataset, DatasetsResponse} from "@google-cloud/bigquery"
import {groupBy, Logger, removeUndefined, zip} from "@azimutt/utils"
import {
    EntityId,
    LegacyColumn,
    LegacyDatabase,
    LegacyIndex,
    LegacyRelation,
    LegacySchemaName,
    LegacyTable,
    LegacyTableName
} from "@azimutt/database-model"
import {Conn} from "./connect"

export type BigquerySchemaOpts = {logger: Logger, catalog: LegacySchemaName | undefined, schema: LegacySchemaName | undefined, entity: LegacyTableName | undefined, sampleSize: number, inferRelations: boolean, ignoreErrors: boolean}
export const getSchema = (opts: BigquerySchemaOpts) => async (conn: Conn): Promise<LegacyDatabase> => {
    const projectId = opts.catalog || await conn.client.getProjectId()
    const datasets: Dataset[] = await conn.client.getDatasets({projectId}).then(([datasets]: DatasetsResponse) => datasets)
    const datasetIds = datasets.map(d => d.id).filter((id: string | undefined): id is string => !!id).filter(id => datasetFilter(id, opts.schema))
    const datasetSchemas = await Promise.all(datasetIds.map(async datasetId => {
        const tables = await getTables(projectId, datasetId, opts)(conn)
        const columns = await getColumns(projectId, datasetId, opts)(conn).then(cols => groupBy(cols, toEntityId))
        const primaryKeys = await getPrimaryKeys(projectId, datasetId, opts)(conn).then(pks => groupBy(pks, toEntityId))
        const foreignKeys = await getForeignKeys(projectId, datasetId, opts)(conn)
        const indexes = await getIndexes(projectId, datasetId, opts)(conn).then(idxs => groupBy(idxs, toEntityId))
        // TODO: inspect JSON columns
        // TODO: inspect polymorphic relations
        return {
            tables: tables.map(table => {
                const id = toEntityId(table)
                return buildTable(table, columns[id] || [], primaryKeys[id] || [], indexes[id] || [])
            }),
            relations: foreignKeys.flatMap(buildRelation)
        }
    }))

    return {
        tables: datasetSchemas.flatMap(s => s.tables),
        relations: datasetSchemas.flatMap(s => s.relations)
    }
}

// 👇️ Private functions, some are exported only for tests
// If you use them, beware of breaking changes!

function toEntityId<T extends { table_catalog: string, table_schema: string, table_name: string }>(value: T): EntityId {
    return `${value.table_catalog}.${value.table_schema}.${value.table_name}`
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

export const getTables = (projectId: string, datasetId: string, opts: BigquerySchemaOpts) => async (conn: Conn): Promise<RawTable[]> => {
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
             , SUM(p.total_rows) AS \`rows\`
             , SUM(p.total_billable_bytes)            AS bytes
             , MAX(p.last_modified_time)              AS last_modified
        FROM ${projectId}.${datasetId}.INFORMATION_SCHEMA.TABLES t
                 LEFT JOIN ${projectId}.${datasetId}.INFORMATION_SCHEMA.PARTITIONS p ON p.table_catalog = t.table_catalog AND p.table_schema = t.table_schema AND p.table_name = t.table_name
                 LEFT JOIN ${projectId}.${datasetId}.INFORMATION_SCHEMA.VIEWS v ON v.table_catalog = t.table_catalog AND v.table_schema = t.table_schema AND v.table_name = t.table_name
                 LEFT JOIN ${projectId}.${datasetId}.INFORMATION_SCHEMA.MATERIALIZED_VIEWS m ON m.table_catalog = t.table_catalog AND m.table_schema = t.table_schema AND m.table_name = t.table_name
                 LEFT JOIN ${projectId}.${datasetId}.INFORMATION_SCHEMA.TABLE_OPTIONS d ON d.table_catalog = t.table_catalog AND d.table_schema = t.table_schema AND d.table_name = t.table_name AND d.option_name = 'description'
                 LEFT JOIN ${projectId}.${datasetId}.INFORMATION_SCHEMA.TABLE_OPTIONS l ON l.table_catalog = t.table_catalog AND l.table_schema = t.table_schema AND l.table_name = t.table_name AND l.option_name = 'labels'
        WHERE t.table_type IN ('BASE TABLE', 'VIEW', 'MATERIALIZED VIEW')${scopeFilter(' AND ', 't.table_catalog', opts.catalog, 't.table_schema', opts.schema, 't.table_name', opts.entity)}
        GROUP BY t.table_catalog, t.table_schema, t.table_name, t.table_type, t.ddl, t.creation_time, v.view_definition, m.last_refresh_time, d.option_value, l.option_value
        ORDER BY t.table_catalog, t.table_schema, t.table_name;`, [], 'getTables'
    ).catch(handleError(`Failed to get tables for ${projectId}.${datasetId}`, [], opts))
}

function buildTable(table: RawTable, columns: RawColumn[], primaryKeys: RawPrimaryKey[], indexes: RawIndex[]): LegacyTable {
    const pk = primaryKeys[0]
    return removeUndefined({
        // catalog: table.table_catalog,
        schema: table.table_schema,
        table: table.table_name,
        columns: columns.slice(0).sort((a, b) => a.column_index - b.column_index).map(c => buildColumn(c)),
        view: table.table_type === 'VIEW' || table.table_type === 'MATERIALIZED VIEW' ? true : undefined,
        primaryKey: pk ? buildPrimaryKey(pk) : undefined,
        uniques: undefined,
        indexes: indexes.length > 0 ? indexes.map(buildIndex) : undefined,
        checks: undefined,
        comment: table.description ? removeQuotes(table.description) : undefined
    })
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

export const getColumns = (projectId: string, datasetId: string, opts: BigquerySchemaOpts) => async (conn: Conn): Promise<RawColumn[]> => {
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
        WHERE c.ordinal_position IS NOT NULL${scopeFilter(' AND ', 'c.table_catalog', opts.catalog, 'c.table_schema', opts.schema, 'c.table_name', opts.entity)}
        ORDER BY c.table_catalog, c.table_schema, c.table_name, c.ordinal_position;`, [], 'getColumns'
    ).catch(handleError(`Failed to get columns for ${projectId}.${datasetId}`, [], opts))
}

function buildColumn(column: RawColumn): LegacyColumn {
    return removeUndefined({
        name: column.column_name,
        type: column.column_type,
        nullable: column.column_nullable || undefined,
        default: column.column_default !== 'NULL' ? column.column_default : undefined,
        comment: column.description || undefined,
        values: undefined,
        columns: undefined
    })
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

export const getPrimaryKeys = (projectId: string, datasetId: string, opts: BigquerySchemaOpts) => async (conn: Conn): Promise<RawPrimaryKey[]> => {
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
        WHERE c.constraint_type = 'PRIMARY KEY'${scopeFilter(' AND ', 'c.table_catalog', opts.catalog, 'c.table_schema', opts.schema, 'c.table_name', opts.entity)}
        GROUP BY c.constraint_catalog, c.constraint_schema, c.constraint_name;`, [], 'getPrimaryKeys'
    ).catch(handleError(`Failed to get primary keys for ${projectId}.${datasetId}`, [], opts))
}

function buildPrimaryKey(pk: RawPrimaryKey) {
    return {
        name: pk.constraint_name,
        columns: pk.table_columns
    }
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

export const getForeignKeys = (projectId: string, datasetId: string, opts: BigquerySchemaOpts) => async (conn: Conn): Promise<RawForeignKey[]> => {
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
        WHERE c.constraint_type = 'FOREIGN KEY'${scopeFilter(' AND ', 'c.table_catalog', opts.catalog, 'c.table_schema', opts.schema, 'c.table_name', opts.entity)}
        GROUP BY c.constraint_catalog, c.constraint_schema, c.constraint_name;`, [], 'getForeignKeys'
    ).catch(handleError(`Failed to get foreign keys for ${projectId}.${datasetId}`, [], opts))
}

function buildRelation(fk: RawForeignKey): LegacyRelation[] {
    return zip(fk.table_columns, fk.target_columns).map(([src_col, ref_col]) => {
        return {
            name: fk.constraint_name,
            src: { schema: fk.table_schema, table: fk.table_name, column: src_col },
            ref: { schema: fk.target_schema, table: fk.target_name, column: ref_col }
        }
    })
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

export const getIndexes = (projectId: string, datasetId: string, opts: BigquerySchemaOpts) => async (conn: Conn): Promise<RawIndex[]> => {
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
        ${scopeFilter('WHERE ', 'i.index_catalog', opts.catalog, 'i.index_schema', opts.schema, 'i.table_name', opts.entity)}
        GROUP BY i.index_catalog, i.index_schema, i.table_name, i.index_name, i.index_status, i.creation_time, i.last_modification_time, i.last_refresh_time, i.disable_reason, i.ddl, i.total_storage_bytes;`, [], 'getIndexes'
    ).catch(handleError(`Failed to get indexes for ${projectId}.${datasetId}`, [], opts))
}

function buildIndex(index: RawIndex): LegacyIndex {
    return {
        name: index.index_name,
        columns: index.index_columns,
        definition: index.ddl
    }
}

function handleError<T>(msg: string, onError: T, {logger, ignoreErrors}: BigquerySchemaOpts) {
    return (err: any): Promise<T> => {
        if (ignoreErrors) {
            logger.warn(`${msg}. Ignoring...`)
            return Promise.resolve(onError)
        } else {
            return Promise.reject(err)
        }
    }
}

function datasetFilter(datasetId: string, schema: LegacySchemaName | undefined): boolean {
    if (schema === undefined) return true
    if (schema === datasetId) return true
    if (schema.indexOf('%') && new RegExp(schema.replaceAll('%', '.*')).exec(datasetId)) return true
    return false
}

function scopeFilter(prefix: string, catalogField?: string, catalogScope?: LegacySchemaName, schemaField?: string, schemaScope?: LegacySchemaName, tableField?: string, tableScope?: LegacyTableName): string {
    const catalogFilter = catalogField && catalogScope ? `${catalogField} ${scopeOp(catalogScope)} '${catalogScope}'` : undefined
    const schemaFilter = schemaField && schemaScope ? `${schemaField} ${scopeOp(schemaScope)} '${schemaScope}'` : undefined
    const tableFilter = tableField && tableScope ? `${tableField} ${scopeOp(tableScope)} '${tableScope}'` : undefined
    const filters = [catalogFilter, schemaFilter, tableFilter].filter((f: string | undefined): f is string => !!f)
    return filters.length > 0 ? prefix + filters.join(' AND ') : ''
}

function scopeOp(scope: string): string {
    return scope.includes('%') ? 'LIKE' : '='
}

function removeQuotes(value: string): string {
    if (value.startsWith('"') && value.endsWith('"')) return value.slice(1, -1)
    if (value.startsWith("'") && value.endsWith("'")) return value.slice(1, -1)
    return value
}
