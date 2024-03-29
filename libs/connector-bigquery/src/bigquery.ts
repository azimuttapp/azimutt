import {BigQueryTimestamp, Dataset, DatasetsResponse} from "@google-cloud/bigquery"
import {groupBy, Logger, removeUndefined, zip} from "@azimutt/utils"
import {
    AzimuttColumn,
    AzimuttRelation,
    AzimuttSchema,
    AzimuttTable,
    SchemaName,
    TableId,
    TableName
} from "@azimutt/database-types"
import {Conn} from "./connect"

export type BigquerySchemaOpts = {logger: Logger, catalog: SchemaName | undefined, schema: SchemaName | undefined, entity: TableName | undefined, sampleSize: number, inferRelations: boolean, ignoreErrors: boolean}
export const getSchema = (opts: BigquerySchemaOpts) => async (conn: Conn): Promise<AzimuttSchema> => {
    const projectId = opts.catalog || await conn.client.getProjectId()
    const datasets: Dataset[] = await conn.client.getDatasets({projectId}).then(([datasets]: DatasetsResponse) => datasets)
    const datasetIds = datasets.map(d => d.id).filter((id: string | undefined): id is string => !!id).filter(id => datasetFilter(id, opts.schema))
    const datasetSchemas = await Promise.all(datasetIds.map(async datasetId => {
        const tables = await getTables(projectId, datasetId, opts)(conn)
        const columns = await getColumns(projectId, datasetId, opts)(conn).then(cols => groupBy(cols, toTableId))
        const primaryKeys = await getPrimaryKeys(projectId, datasetId, opts)(conn).then(cols => groupBy(cols, toTableId))
        const foreignKeys = await getForeignKeys(projectId, datasetId, opts)(conn)
        // TODO indexes
        // TODO comments
        return {
            tables: tables.map(table => {
                const id = toTableId(table)
                return buildTable(table, columns[id] || [], primaryKeys[id] || [])
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

function buildTable(table: RawTable, columns: RawColumn[], primaryKeys: RawPrimaryKey[]): AzimuttTable {
    const pk = primaryKeys[0]
    return removeUndefined({
        // catalog: table.table_catalog,
        schema: table.table_schema,
        table: table.table_name,
        columns: columns.slice(0).sort((a, b) => a.column_index - b.column_index).map(c => buildColumn(c)),
        view: table.table_type === 'VIEW' || table.table_type === 'MATERIALIZED VIEW' ? true : undefined,
        primaryKey: pk ? buildPrimaryKey(pk) : undefined,
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

function buildRelation(fk: RawForeignKey): AzimuttRelation[] {
    return zip(fk.table_columns, fk.target_columns).map(([src_col, ref_col]) => {
        return {
            name: fk.constraint_name,
            src: { schema: fk.table_schema, table: fk.table_name, column: src_col },
            ref: { schema: fk.target_schema, table: fk.target_name, column: ref_col }
        }
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
