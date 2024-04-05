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
    parseDatabase,
    parseDatabaseOptions,
    QueryAnalyze,
    QueryResults
} from "@azimutt/database-model";
import {connect} from "./connect";
import {execQuery} from "./query";
import {getSchema} from "./postgres";
import {getColumnStats, getTableStats} from "./stats";

export const postgres: Connector = {
    name: 'PostgreSQL',
    getSchema: (application: string, url: DatabaseUrlParsed, opts: ConnectorSchemaOpts): Promise<Database> => {
        const urlOptions = parseDatabaseOptions(url.options)
        const options: ConnectorSchemaOpts = {
            ...opts,
            schema: opts.schema || urlOptions['schema'],
            entity: opts.entity || urlOptions['table']
        }
        return connect(application, url, getSchema(options), options).then(parseDatabase)
    },
    getQueryHistory: (application: string, url: DatabaseUrlParsed, opts: ConnectorQueryHistoryOpts): Promise<DatabaseQuery[]> =>
        Promise.reject('Not implemented'),
    execute: (application: string, url: DatabaseUrlParsed, query: string, parameters: any[], opts: ConnectorDefaultOpts): Promise<QueryResults> =>
        connect(application, url, execQuery(query, parameters), opts).then(QueryResults.parse),
    analyze: (application: string, url: DatabaseUrlParsed, query: string, parameters: any[], opts: ConnectorDefaultOpts): Promise<QueryAnalyze> =>
        Promise.reject('Not implemented'),
    getEntityStats: (application: string, url: DatabaseUrlParsed, ref: EntityRef, opts: ConnectorDefaultOpts): Promise<ConnectorEntityStats> =>
        connect(application, url, getTableStats(ref), opts).then(ConnectorEntityStats.parse),
    getAttributeStats: (application: string, url: DatabaseUrlParsed, ref: AttributeRef, opts: ConnectorDefaultOpts): Promise<ConnectorAttributeStats> =>
        connect(application, url, getColumnStats(ref), opts).then(ConnectorAttributeStats.parse)
}
