import {groupBy, Logger, removeUndefined} from "@azimutt/utils"
import {AzimuttColumn, AzimuttSchema, AzimuttTable, SchemaName, TableId, TableName} from "@azimutt/database-types"
import {BigQueryTimestamp, Dataset, DatasetsResponse} from "@google-cloud/bigquery"
import {Conn} from "./connect"

export type BigquerySchemaOpts = {logger: Logger, catalog: SchemaName | undefined, schema: SchemaName | undefined, entity: TableName | undefined, sampleSize: number, inferRelations: boolean, ignoreErrors: boolean}
export const getSchema = (opts: BigquerySchemaOpts) => async (conn: Conn): Promise<AzimuttSchema> => {
    const projectId = opts.catalog || await conn.client.getProjectId()
    const datasets: Dataset[] = await conn.client.getDatasets({projectId}).then(([datasets]: DatasetsResponse) => datasets)
    const datasetIds = datasets.map(d => d.id).filter((id: string | undefined): id is string => !!id).filter(id => datasetFilter(id, opts.schema))
    const datasetSchemas = await Promise.all(datasetIds.map(async datasetId => {
        const tables = await getTables(projectId, datasetId, opts)(conn)
        const columns = await getColumns(projectId, datasetId, opts)(conn).then(cols => groupBy(cols, toTableId))
        return {
            tables: tables.map(table => {
                const id = toTableId(table)
                return buildTable(table, columns[id] || [])
            }),
            relations: []
        }
    }))

    return {
        tables: datasetSchemas.flatMap(s => s.tables),
        relations: datasetSchemas.flatMap(s => s.relations)
    }
}

// 👇️ Private functions, some are exported only for tests
// If you use them, beware of breaking changes!

function toTableId<T extends { table_catalog: string, table_schema: string, table_name: string }>(value: T): TableId {
    return `${value.table_catalog}.${value.table_schema}.${value.table_name}`
}

export type RawTable = {
    table_catalog: string
    table_schema: string
    table_name: string
    table_type: 'BASE TABLE' | 'VIEW' | 'MATERIALIZED VIEW' | 'EXTERNAL' | 'CLONE' | 'SNAPSHOT'
    ddl: string
    creation_time: BigQueryTimestamp
}

export const getTables = (projectId: string, datasetId: string, opts: BigquerySchemaOpts) => async (conn: Conn): Promise<RawTable[]> => {
    // https://cloud.google.com/bigquery/docs/information-schema-tables
    return conn.query<RawTable>(`
        SELECT table_catalog
             , table_schema
             , table_name
             , table_type
             , ddl
             , creation_time
        FROM ${projectId}.${datasetId}.INFORMATION_SCHEMA.TABLES
        WHERE table_type IN ('BASE TABLE', 'VIEW', 'MATERIALIZED VIEW')${scopeFilter(' AND ', 'table_catalog', opts.catalog, 'table_schema', opts.schema, 'table_name', opts.entity)}
        ORDER BY table_catalog, table_schema, table_name;`, [], 'getTables'
    ).catch(handleError(`Failed to get tables for ${projectId}.${datasetId}`, [], opts))
}

function buildTable(table: RawTable, columns: RawColumn[]): AzimuttTable {
    return removeUndefined({
        // catalog: table.table_catalog,
        schema: table.table_schema,
        table: table.table_name,
        columns: columns.slice(0).sort((a, b) => a.column_index - b.column_index).map(c => buildColumn(c)),
        view: table.table_type === 'VIEW' || table.table_type === 'MATERIALIZED VIEW' ? true : undefined,
        primaryKey: undefined,
        uniques: undefined,
        indexes: undefined,
        checks: undefined,
        comment: undefined
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
}

export const getColumns = (projectId: string, datasetId: string, opts: BigquerySchemaOpts) => async (conn: Conn): Promise<RawColumn[]> => {
    // https://cloud.google.com/bigquery/docs/information-schema-columns
    return conn.query<RawColumn>(`
        SELECT table_catalog
             , table_schema
             , table_name
             , ordinal_position AS column_index
             , column_name
             , data_type AS column_type
             , column_default AS column_default
             , is_nullable = 'YES' AS column_nullable
             , is_partitioning_column = 'YES' AS column_partitioning
        FROM ${projectId}.${datasetId}.INFORMATION_SCHEMA.COLUMNS
        WHERE ordinal_position IS NOT NULL${scopeFilter(' AND ', 'table_catalog', opts.catalog, 'table_schema', opts.schema, 'table_name', opts.entity)}
        ORDER BY table_catalog, table_schema, table_name, column_index;`, [], 'getColumns'
    ).catch(handleError(`Failed to get columns for ${projectId}.${datasetId}`, [], opts))
}

function buildColumn(column: RawColumn): AzimuttColumn {
    return removeUndefined({
        name: column.column_name,
        type: column.column_type,
        nullable: column.column_nullable || undefined,
        default: column.column_default,
        comment: undefined,
        values: undefined,
        columns: undefined
    })
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

function scopeFilter(prefix: string, catalogField?: string, catalogScope?: SchemaName, schemaField?: string, schemaScope?: SchemaName, tableField?: string, tableScope?: TableName): string {
    const catalogFilter = catalogField && catalogScope ? `${catalogField} ${scopeOp(catalogScope)} '${catalogScope}'` : undefined
    const schemaFilter = schemaField && schemaScope ? `${schemaField} ${scopeOp(schemaScope)} '${schemaScope}'` : undefined
    const tableFilter = tableField && tableScope ? `${tableField} ${scopeOp(tableScope)} '${tableScope}'` : undefined
    const filters = [catalogFilter, schemaFilter, tableFilter].filter((f: string | undefined): f is string => !!f)
    return filters.length > 0 ? prefix + filters.join(' AND ') : ''
}

function scopeOp(scope: string): string {
    return scope.includes('%') ? 'LIKE' : '='
}

function datasetFilter(datasetId: string, schema: SchemaName | undefined): boolean {
    if (schema === undefined) return true
    if (schema === datasetId) return true
    if (schema.indexOf('%') && new RegExp(schema.replaceAll('%', '.*')).exec(datasetId)) return true
    return false
}
