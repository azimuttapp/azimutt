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
import {execQuery, formatSchema, getSchema} from "./mongodb";

export * from "./mongodb"

export const mongodb: Connector = {
    name: 'MongoDb',
    query: (application: string, url: DatabaseUrlParsed, query: string, parameters: any[]): Promise<DatabaseResults> =>
        execQuery(application, url, query).then(r => ({rows: r.rows})), // remove additional properties from QueryResult
    getSchema: async (application: string, url: DatabaseUrlParsed, opts: SchemaOpts): Promise<AzimuttSchema> => {
        const schema = await getSchema(application, url, opts.schema, opts.sampleSize || 100, opts.logger)
        return formatSchema(schema, opts.inferRelations || false)
    },
    getTableStats: (application: string, url: DatabaseUrlParsed, id: TableId): Promise<TableStats> =>
        Promise.reject(`'getTableStats' not implemented in MongoDb`),
    getColumnStats: (application: string, url: DatabaseUrlParsed, ref: ColumnRef): Promise<ColumnStats> =>
        Promise.reject(`'getColumnStats' not implemented in MongoDb`)
}
