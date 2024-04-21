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
    parseDatabaseOptions,
    QueryAnalyze,
    QueryResults,
    zodParseAsync
} from "@azimutt/models";
import {connect} from "./connect";
import {execQuery} from "./query";
import {getSchema} from "./mysql";
import {getColumnStats, getTableStats} from "./stats";

export const mysql: Connector = {
    name: 'MySQL',
    getSchema: (application: string, url: DatabaseUrlParsed, opts: ConnectorSchemaOpts): Promise<Database> => {
        const urlOptions = parseDatabaseOptions(url.options)
        const options: ConnectorSchemaOpts = {
            ...opts,
            schema: opts.schema || urlOptions['schema'],
            entity: opts.entity || urlOptions['table']
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
        connect(application, url, getTableStats(ref), opts).then(zodParseAsync(ConnectorEntityStats)),
    getAttributeStats: (application: string, url: DatabaseUrlParsed, ref: AttributeRef, opts: ConnectorDefaultOpts): Promise<ConnectorAttributeStats> =>
        connect(application, url, getColumnStats(ref), opts).then(zodParseAsync(ConnectorAttributeStats))
}
