import {AzimuttSchema, Connector, DatabaseResults, DatabaseUrlParsed, SchemaOpts} from "@azimutt/database-types";
import {execQuery, formatSchema, getSchema} from "./postgres";
import {getColumnStats, getTableStats} from "./stats";

export * from "./postgres"
export * from "./stats"

export const postgres: Connector = {
    name: 'PostgreSQL',
    query: (application: string, url: DatabaseUrlParsed, query: string, parameters: any[]): Promise<DatabaseResults> =>
        execQuery(application, url, query, parameters).then(r => ({rows: r.rows})), // remove additional properties from pg.QueryResult
    getSchema: async (application: string, url: DatabaseUrlParsed, opts: SchemaOpts): Promise<AzimuttSchema> => {
        const schema = await getSchema(application, url, opts.schema, opts.sampleSize || 100, opts.logger)
        return formatSchema(schema, opts.inferRelations || false)
    },
    getTableStats: getTableStats,
    getColumnStats: getColumnStats
}
