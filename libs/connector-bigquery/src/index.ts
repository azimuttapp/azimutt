import {
    AzimuttSchema,
    ColumnRef,
    ColumnStats,
    Connector,
    ConnectorOpts,
    DatabaseQueryResults,
    DatabaseUrlParsed,
    parseDatabaseOptions,
    SchemaOpts,
    TableId,
    TableStats
} from "@azimutt/database-types";
import {BigqueryConnectOpts, connect} from "./connect";
import {BigquerySchemaOpts, getSchema} from "./bigquery";
import {execQuery} from "./query";

export const bigquery: Connector = {
    name: 'BigQuery',
    getSchema: async (application: string, url: DatabaseUrlParsed, opts: ConnectorOpts & SchemaOpts): Promise<AzimuttSchema> => {
        const connectOpts: BigqueryConnectOpts = {logger: opts.logger, logQueries: withDefault(opts.logQueries, false)}
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
        return await connect(application, url, getSchema(schemaOpts), connectOpts)
    },
    query: (application: string, url: DatabaseUrlParsed, query: string, parameters: any[], opts: ConnectorOpts): Promise<DatabaseQueryResults> => {
        const connectOpts: BigqueryConnectOpts = {logger: opts.logger, logQueries: withDefault(opts.logQueries, false)}
        return connect(application, url, execQuery(query, parameters), connectOpts)
    },
    getTableStats: (application: string, url: DatabaseUrlParsed, id: TableId, opts: ConnectorOpts): Promise<TableStats> =>
        Promise.reject(new Error('getTableStats not implemented')),
    getColumnStats: (application: string, url: DatabaseUrlParsed, ref: ColumnRef, opts: ConnectorOpts): Promise<ColumnStats> =>
        Promise.reject(new Error('getColumnStats not implemented')),
}

function withDefault<T>(value: T | undefined, other: T): T {
    return value === undefined ? other : value
}
