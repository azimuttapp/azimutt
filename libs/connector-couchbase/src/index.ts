import {
    AzimuttSchema,
    ColumnRef,
    ColumnStats,
    Connector,
    DatabaseResults,
    DatabaseUrlParsed,
    SchemaOpts,
    TableId,
    TableStats
} from "@azimutt/database-types";
import {formatSchema, getSchema} from "./couchbase";

export * from "./couchbase"

const name = 'Couchbase'
export const couchbase: Connector = {
    name,
    query: (application: string, url: DatabaseUrlParsed, query: string, values: any[]): Promise<DatabaseResults> => Promise.reject(`'query' not implemented in ${name}`),
    getSchema: async (application: string, url: DatabaseUrlParsed, opts: SchemaOpts): Promise<AzimuttSchema> => {
        const schema = await getSchema(application, url, opts.schema, opts.sampleSize || 100, opts.logger)
        return formatSchema(schema, opts.inferRelations || false)
    },
    getTableStats: (application: string, url: DatabaseUrlParsed, id: TableId): Promise<TableStats> => Promise.reject(`'getTableStats' not implemented in ${name}`),
    getColumnStats: (application: string, url: DatabaseUrlParsed, ref: ColumnRef): Promise<ColumnStats> => Promise.reject(`'getColumnStats' not implemented in ${name}`)
}
