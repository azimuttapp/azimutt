import {AzimuttSchema, Connector, DatabaseUrlParsed, SchemaOpts} from "@azimutt/database-types";
import {execQuery, formatSchema, getSchema} from "./postgres";
import {getColumnStats, getTableStats} from "./stats";

export * from "./postgres"
export * from "./stats"

export const postgres: Connector = {
    name: 'PostgreSQL',
    query: execQuery,
    getSchema: async (application: string, url: DatabaseUrlParsed, opts: SchemaOpts): Promise<AzimuttSchema> => {
        const schema = await getSchema(application, url, opts.schema, opts.sampleSize || 100, opts.logger)
        return formatSchema(schema, opts.inferRelations || false)
    },
    getTableStats: getTableStats,
    getColumnStats: getColumnStats
}
