import {distinct} from "@azimutt/utils";
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
import {CouchbaseSchemaOpts, execQuery, formatSchema, getSchema} from "./couchbase";
import {connect} from "./connect";

export * from "./couchbase"

export const couchbase: Connector = {
    name: 'Couchbase',
    getSchema: async (application: string, url: DatabaseUrlParsed, opts: ConnectorSchemaOpts): Promise<Database> => {
        const schemaOpts: CouchbaseSchemaOpts = {
            logger: opts.logger,
            bucket: opts.schema,
            mixedCollection: opts.inferMixedJson,
            sampleSize: withDefault(opts.sampleSize, 100),
            ignoreErrors: withDefault(opts.ignoreErrors, false)
        }
        const schema = await connect(application, url, getSchema(schemaOpts))
        return databaseFromLegacy(formatSchema(schema))
    },
    getQueryHistory: (application: string, url: DatabaseUrlParsed, opts: ConnectorQueryHistoryOpts): Promise<DatabaseQuery[]> =>
        Promise.reject('Not implemented'),
    execute: (application: string, url: DatabaseUrlParsed, query: string, parameters: any[], opts: ConnectorDefaultOpts): Promise<QueryResults> =>
        connect(application, url, execQuery(query, parameters)).then(r => ({
            query,
            attributes: distinct(r.rows.flatMap(Object.keys)).map(name => ({name})),
            rows: r.rows
        })),
    analyze: (application: string, url: DatabaseUrlParsed, query: string, parameters: any[], opts: ConnectorDefaultOpts): Promise<QueryAnalyze> =>
        Promise.reject('Not implemented'),
    getEntityStats: (application: string, url: DatabaseUrlParsed, ref: EntityRef, opts: ConnectorDefaultOpts): Promise<ConnectorEntityStats> =>
        Promise.reject('Not implemented'),
    getAttributeStats: (application: string, url: DatabaseUrlParsed, ref: AttributeRef, opts: ConnectorDefaultOpts): Promise<ConnectorAttributeStats> =>
        Promise.reject('Not implemented')
}

function withDefault<T>(value: T | undefined, other: T): T {
    return value === undefined ? other : value
}
