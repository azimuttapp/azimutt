import {
    AttributeRef,
    Connector,
    ConnectorAttributeStats,
    ConnectorDefaultOpts,
    ConnectorEntityStats,
    ConnectorQueryHistoryOpts,
    ConnectorSchemaOpts,
    Database,
    databaseFromLegacy,
    DatabaseQuery,
    DatabaseUrlParsed,
    EntityRef,
    parseDatabaseOptions,
    QueryAnalyze,
    QueryResults
} from "@azimutt/database-model";
import {connect} from "./connect";
import {BigquerySchemaOpts, getSchema} from "./bigquery";
import {execQuery} from "./query";

export const bigquery: Connector = {
    name: 'BigQuery',
    getSchema: async (application: string, url: DatabaseUrlParsed, opts: ConnectorSchemaOpts): Promise<Database> => {
        const options = parseDatabaseOptions(url.options)
        const schemaOpts: BigquerySchemaOpts = {
            logger: opts.logger,
            catalog: url.db || options['project'],
            schema: opts.schema || options['dataset'],
            entity: options['table'],
            sampleSize: withDefault(opts.sampleSize, 100),
            inferRelations: withDefault(opts.inferRelations, true),
            ignoreErrors: withDefault(opts.ignoreErrors, false)
        }
        return databaseFromLegacy(await connect(application, url, getSchema(schemaOpts), opts))
    },
    getQueryHistory: (application: string, url: DatabaseUrlParsed, opts: ConnectorQueryHistoryOpts): Promise<DatabaseQuery[]> =>
        Promise.reject(new Error('Not implemented')),
    execute: (application: string, url: DatabaseUrlParsed, query: string, parameters: any[], opts: ConnectorDefaultOpts): Promise<QueryResults> =>
        connect(application, url, execQuery(query, parameters), opts),
    analyze: (application: string, url: DatabaseUrlParsed, query: string, parameters: any[], opts: ConnectorDefaultOpts): Promise<QueryAnalyze> =>
        Promise.reject(new Error('Not implemented')),
    getEntityStats: (application: string, url: DatabaseUrlParsed, ref: EntityRef, opts: ConnectorDefaultOpts): Promise<ConnectorEntityStats> =>
        Promise.reject(new Error('Not implemented')),
    getAttributeStats: (application: string, url: DatabaseUrlParsed, ref: AttributeRef, opts: ConnectorDefaultOpts): Promise<ConnectorAttributeStats> =>
        Promise.reject(new Error('Not implemented')),
}

function withDefault<T>(value: T | undefined, other: T): T {
    return value === undefined ? other : value
}
