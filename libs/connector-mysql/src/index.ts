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
    QueryAnalyze,
    QueryResults
} from "@azimutt/database-model";
import {connect} from "./connect";
import {formatSchema, getSchema, MysqlSchemaOpts} from "./mysql";
import {execQuery} from "./common";
import {getColumnStats, getTableStats} from "./stats";

export const mysql: Connector = {
    name: 'MySQL',
    getSchema: async (application: string, url: DatabaseUrlParsed, opts: ConnectorSchemaOpts): Promise<Database> => {
        const schemaOpts: MysqlSchemaOpts = {
            logger: opts.logger,
            schema: opts.schema,
            sampleSize: withDefault(opts.sampleSize, 100),
            inferRelations: withDefault(opts.inferRelations, true),
            ignoreErrors: withDefault(opts.ignoreErrors, false)
        }
        const schema = await connect(application, url, getSchema(schemaOpts), opts)
        return databaseFromLegacy(formatSchema(schema))
    },
    getQueryHistory: (application: string, url: DatabaseUrlParsed, opts: ConnectorQueryHistoryOpts): Promise<DatabaseQuery[]> =>
        Promise.reject('Not implemented'),
    execute: (application: string, url: DatabaseUrlParsed, query: string, parameters: any[], opts: ConnectorDefaultOpts): Promise<QueryResults> =>
        connect(application, url, execQuery(query, parameters), opts),
    analyze: (application: string, url: DatabaseUrlParsed, query: string, parameters: any[], opts: ConnectorDefaultOpts): Promise<QueryAnalyze> =>
        Promise.reject('Not implemented'),
    getEntityStats: (application: string, url: DatabaseUrlParsed, ref: EntityRef, opts: ConnectorDefaultOpts): Promise<ConnectorEntityStats> =>
        connect(application, url, getTableStats(ref), opts),
    getAttributeStats: (application: string, url: DatabaseUrlParsed, ref: AttributeRef, opts: ConnectorDefaultOpts): Promise<ConnectorAttributeStats> =>
        connect(application, url, getColumnStats(ref), opts)
}

function withDefault<T>(value: T | undefined, other: T): T {
    return value === undefined ? other : value
}
