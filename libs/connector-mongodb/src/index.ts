import {
    AttributeRef,
    Connector,
    ConnectorAttributeStats,
    ConnectorDefaultOpts,
    ConnectorEntityStats,
    ConnectorQueryHistoryOpts,
    ConnectorSchemaOpts,
    Database,
    DatabaseQuery,
    DatabaseUrlParsed,
    EntityRef,
    QueryAnalyze,
    QueryResults,
    zodParseAsync
} from "@azimutt/models";
import {connect} from "./connect";
import {execQuery} from "./query";
import {getSchema} from "./mongodb";

export const mongodb: Connector = {
    name: 'MongoDb',
    getSchema: (application: string, url: DatabaseUrlParsed, opts: ConnectorSchemaOpts): Promise<Database> => {
        const urlOptions = url.options || {}
        const options: ConnectorSchemaOpts = {
            ...opts,
            database: opts.database || urlOptions['database'] || url.db,
            entity: opts.entity || urlOptions['collection']
        }
        return connect(application, url, getSchema(options), options).then(zodParseAsync(Database))
    },
    getQueryHistory: (application: string, url: DatabaseUrlParsed, opts: ConnectorQueryHistoryOpts): Promise<DatabaseQuery[]> =>
        Promise.reject('Not implemented'),
    execute: (application: string, url: DatabaseUrlParsed, query: string, parameters: any[], opts: ConnectorDefaultOpts): Promise<QueryResults> =>
        connect(application, url, execQuery(query, parameters), opts).then(zodParseAsync(QueryResults)),
    analyze: (application: string, url: DatabaseUrlParsed, query: string, parameters: any[], opts: ConnectorDefaultOpts): Promise<QueryAnalyze> =>
        Promise.reject('Not implemented'),
    getEntityStats: (application: string, url: DatabaseUrlParsed, ref: EntityRef, opts: ConnectorDefaultOpts): Promise<ConnectorEntityStats> =>
        Promise.reject('Not implemented'),
    getAttributeStats: (application: string, url: DatabaseUrlParsed, ref: AttributeRef, opts: ConnectorDefaultOpts): Promise<ConnectorAttributeStats> =>
        Promise.reject('Not implemented')
}
