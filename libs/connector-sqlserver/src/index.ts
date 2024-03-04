import {
    AzimuttSchema,
    ColumnRef,
    ColumnStats,
    Connector,
    ConnectorOps,
    DatabaseQueryResults,
    DatabaseUrlParsed,
    SchemaOpts,
    TableId,
    TableStats
} from "@azimutt/database-types";
import {execQuery} from "./common";
import {connect, SqlserverConnectOpts} from "./connect";
import {formatSchema, getSchema, SqlserverSchemaOpts} from "./sqlserver";
import {getColumnStats, getTableStats} from "./stats";

export const sqlserver: Connector = {
    name: 'SQL Server',
    getSchema: async (application: string, url: DatabaseUrlParsed, opts: ConnectorOps & SchemaOpts): Promise<AzimuttSchema> => {
        const connectOpts: SqlserverConnectOpts = {logger: opts.logger, logQueries: withDefault(opts.logQueries, false)}
        const schemaOpts: SqlserverSchemaOpts = {
            logger: opts.logger,
            schema: opts.schema,
            sampleSize: withDefault(opts.sampleSize, 100),
            inferRelations: withDefault(opts.inferRelations, true),
            ignoreErrors: withDefault(opts.ignoreErrors, false)
        }
        const schema = await connect(application, url, getSchema(schemaOpts), connectOpts)
        return formatSchema(schema)
    },
    getTableStats: (application: string, url: DatabaseUrlParsed, id: TableId, opts: ConnectorOps): Promise<TableStats> => {
        const connectOpts: SqlserverConnectOpts = {logger: opts.logger, logQueries: withDefault(opts.logQueries, false)}
        return connect(application, url, getTableStats(id), connectOpts)
    },
    getColumnStats: (application: string, url: DatabaseUrlParsed, ref: ColumnRef, opts: ConnectorOps): Promise<ColumnStats> => {
        const connectOpts: SqlserverConnectOpts = {logger: opts.logger, logQueries: withDefault(opts.logQueries, false)}
        return connect(application, url, getColumnStats(ref), connectOpts)
    },
    query: (application: string, url: DatabaseUrlParsed, query: string, parameters: any[], opts: ConnectorOps): Promise<DatabaseQueryResults> => {
        const connectOpts: SqlserverConnectOpts = {logger: opts.logger, logQueries: withDefault(opts.logQueries, false)}
        return connect(application, url, execQuery(query, parameters), connectOpts)
    },
}

function withDefault<T>(value: T | undefined, other: T): T {
    return value === undefined ? other : value
}
