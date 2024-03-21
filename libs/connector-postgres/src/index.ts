import * as old from "@azimutt/database-types";
import {
    AttributeRef,
    Connector,
    ConnectorAttributeStats,
    ConnectorEntityStats,
    ConnectorExecuteOpts,
    ConnectorExecuteResults,
    ConnectorQueryStats,
    ConnectorQueryStatsOpts,
    ConnectorSchemaOpts,
    Database,
    DatabaseUrlParsed,
    EntityRef
} from "@azimutt/database-model";
import {execQuery} from "./common";
import {connect} from "./connect";
import {formatSchema, getSchema, PostgresSchemaOpts} from "./postgres";
import {getColumnStats, getTableStats} from "./stats";

export const postgres: old.Connector = {
    name: 'PostgreSQL',
    getSchema: async (application: string, url: old.DatabaseUrlParsed, opts: old.ConnectorOps & old.SchemaOpts): Promise<old.AzimuttSchema> => {
        const schemaOpts: PostgresSchemaOpts = {
            logger: opts.logger,
            schema: opts.schema,
            sampleSize: withDefault(opts.sampleSize, 100),
            inferRelations: withDefault(opts.inferRelations, true),
            ignoreErrors: withDefault(opts.ignoreErrors, false)
        }
        const schema = await connect(application, url, getSchema(schemaOpts), opts)
        return formatSchema(schema)
    },
    getTableStats: (application: string, url: old.DatabaseUrlParsed, id: old.TableId, opts: old.ConnectorOps): Promise<old.TableStats> => {
        return connect(application, url, getTableStats(id), opts)
    },
    getColumnStats: (application: string, url: old.DatabaseUrlParsed, ref: old.ColumnRef, opts: old.ConnectorOps): Promise<old.ColumnStats> => {
        return connect(application, url, getColumnStats(ref), opts)
    },
    query: (application: string, url: old.DatabaseUrlParsed, query: string, parameters: any[], opts: old.ConnectorOps): Promise<old.DatabaseQueryResults> => {
        return connect(application, url, execQuery(query, parameters), opts)
    },
}

function withDefault<T>(value: T | undefined, other: T): T {
    return value === undefined ? other : value
}

export const postgres2: Connector = {
    name: 'PostgreSQL',
    getSchema: (application: string, url: DatabaseUrlParsed, opts: ConnectorSchemaOpts): Promise<Database> => {
        return Promise.reject('Not implemented') // TODO: new Connector
    },
    execute: (application: string, url: DatabaseUrlParsed, query: string, parameters: any[], opts: ConnectorExecuteOpts): Promise<ConnectorExecuteResults> => {
        return Promise.reject('Not implemented')
    },
    getQueryStats: (application: string, url: DatabaseUrlParsed, opts: ConnectorQueryStatsOpts): Promise<ConnectorQueryStats[]> => {
        return Promise.reject('Not implemented')
    },
    getEntityStats: (application: string, url: DatabaseUrlParsed, entity: EntityRef): Promise<ConnectorEntityStats> => {
        return Promise.reject('Not implemented')
    },
    getAttributeStats: (application: string, url: DatabaseUrlParsed, attribute: AttributeRef): Promise<ConnectorAttributeStats> => {
        return Promise.reject('Not implemented')
    }
}
