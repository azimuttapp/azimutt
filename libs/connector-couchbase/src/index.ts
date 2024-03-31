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
    QueryResults
} from "@azimutt/database-model";
import {connect} from "./connect";
import {execQuery} from "./query";
import {getSchema} from "./couchbase";

export const couchbase: Connector = {
    name: 'Couchbase',
    getSchema: (application: string, url: DatabaseUrlParsed, opts: ConnectorSchemaOpts): Promise<Database> =>
        connect(application, url, getSchema(opts), opts),
    getQueryHistory: (application: string, url: DatabaseUrlParsed, opts: ConnectorQueryHistoryOpts): Promise<DatabaseQuery[]> =>
        Promise.reject('Not implemented'),
    execute: (application: string, url: DatabaseUrlParsed, query: string, parameters: any[], opts: ConnectorDefaultOpts): Promise<QueryResults> =>
        connect(application, url, execQuery(query, parameters), opts),
    analyze: (application: string, url: DatabaseUrlParsed, query: string, parameters: any[], opts: ConnectorDefaultOpts): Promise<QueryAnalyze> =>
        Promise.reject('Not implemented'),
    getEntityStats: (application: string, url: DatabaseUrlParsed, ref: EntityRef, opts: ConnectorDefaultOpts): Promise<ConnectorEntityStats> =>
        Promise.reject('Not implemented'),
    getAttributeStats: (application: string, url: DatabaseUrlParsed, ref: AttributeRef, opts: ConnectorDefaultOpts): Promise<ConnectorAttributeStats> =>
        Promise.reject('Not implemented')
}
