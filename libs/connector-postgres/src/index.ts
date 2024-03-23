import * as old from "@azimutt/database-types";
import {DatabaseQueryResults} from "@azimutt/database-types";
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
import {execQuery} from "./common";
import {connect} from "./connect";
import * as legacy from "./postgres";
import {getColumnStats, getTableStats} from "./stats";
import {getSchema} from "./postgres2";
import {removeUndefined} from "@azimutt/utils";

export const postgres2: Connector = {
    name: 'PostgreSQL',
    getSchema: (application: string, url: DatabaseUrlParsed, opts: ConnectorSchemaOpts): Promise<Database> =>
        connect(application, url, getSchema(opts), opts),
    getQueryHistory: (application: string, url: DatabaseUrlParsed, opts: ConnectorQueryHistoryOpts): Promise<DatabaseQuery[]> =>
        Promise.reject('Not implemented'),
    execute: (application: string, url: DatabaseUrlParsed, query: string, parameters: any[], opts: ConnectorDefaultOpts): Promise<QueryResults> =>
        connect(application, url, execQuery(query, parameters), opts),
    analyze: (application: string, url: DatabaseUrlParsed, query: string, parameters: any[], opts: ConnectorDefaultOpts): Promise<QueryAnalyze> =>
        Promise.reject('Not implemented'),
    getEntityStats: (application: string, url: DatabaseUrlParsed, entity: EntityRef): Promise<ConnectorEntityStats> =>
        Promise.reject('Not implemented'),
    getAttributeStats: (application: string, url: DatabaseUrlParsed, attribute: AttributeRef): Promise<ConnectorAttributeStats> =>
        Promise.reject('Not implemented')
}

export const postgres: old.Connector = {
    name: 'PostgreSQL',
    getSchema: async (application: string, url: old.DatabaseUrlParsed, opts: old.ConnectorOps & old.SchemaOpts): Promise<old.AzimuttSchema> => {
        const schemaOpts: legacy.PostgresSchemaOpts = {
            logger: opts.logger,
            schema: opts.schema,
            sampleSize: withDefault(opts.sampleSize, 100),
            inferRelations: withDefault(opts.inferRelations, true),
            ignoreErrors: withDefault(opts.ignoreErrors, false)
        }
        const schema = await connect(application, url, legacy.getSchema(schemaOpts), opts)
        return legacy.formatSchema(schema)
    },
    getTableStats: (application: string, url: old.DatabaseUrlParsed, id: old.TableId, opts: old.ConnectorOps): Promise<old.TableStats> => {
        return connect(application, url, getTableStats(id), opts)
    },
    getColumnStats: (application: string, url: old.DatabaseUrlParsed, ref: old.ColumnRef, opts: old.ConnectorOps): Promise<old.ColumnStats> => {
        return connect(application, url, getColumnStats(ref), opts)
    },
    query: (application: string, url: old.DatabaseUrlParsed, query: string, parameters: any[], opts: old.ConnectorOps): Promise<old.DatabaseQueryResults> => {
        return connect(application, url, execQuery(query, parameters), opts).then(legacyResults)
    },
}

function legacyResults(results: QueryResults): DatabaseQueryResults {
    return {
        ...results,
        columns: results.attributes.map(a => {
            return removeUndefined({
                name: a.name,
                ref: a.ref ? {table: `${a.ref.schema}.${a.ref.entity}`, column: a.ref.attribute[0]} : undefined
            })
        })
    }
}

function withDefault<T>(value: T | undefined, other: T): T {
    return value === undefined ? other : value
}
