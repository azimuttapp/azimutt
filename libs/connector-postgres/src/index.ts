import {AzimuttSchema, Connector, DatabaseQueryResults, DatabaseUrlParsed, SchemaOpts} from "@azimutt/database-types";
import {formatSchema, getSchema} from "./postgres";
import {execQuery} from "./query";
import {getColumnStats, getTableStats} from "./stats";

export * from "./postgres"
export * from "./query"
export * from "./stats"

export const postgres: Connector = {
    name: 'PostgreSQL',
    getSchema: async (application: string, url: DatabaseUrlParsed, opts: SchemaOpts): Promise<AzimuttSchema> => {
        const schema = await getSchema(application, url, opts.schema, opts.sampleSize || 100, opts.logger)
        return formatSchema(schema, opts.inferRelations || false)
    },
    getTableStats: getTableStats,
    getColumnStats: getColumnStats,
    query: (application: string, url: DatabaseUrlParsed, query: string, parameters: any[]): Promise<DatabaseQueryResults> =>
        execQuery(application, url, query, parameters),
}
