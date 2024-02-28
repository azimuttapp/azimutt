import {Logger} from "@azimutt/utils";
import {
    AzimuttSchema,
    ColumnRef,
    ColumnStats,
    Connector,
    DatabaseQueryResults,
    DatabaseUrlParsed,
    SchemaOpts,
    TableId,
    TableStats
} from "@azimutt/database-types";
import {execQuery} from "./common";
import {connect} from "./connect";
import {formatSchema, getSchema} from "./sqlserver";
import {getColumnStats, getTableStats} from "./stats";

const logger: Logger = {
    debug: (text: string) => console.debug(text),
    log: (text: string) => console.log(text),
    warn: (text: string) => console.warn(text),
    error: (text: string) => console.error(text)
}

export const sqlserver: Connector = {
    name: 'SQL Server',
    getSchema: async (application: string, url: DatabaseUrlParsed, opts: SchemaOpts): Promise<AzimuttSchema> => {
        const pageSize = 1000
        const schema = await connect(application, url, getSchema(opts.schema, pageSize, opts.sampleSize || 100, opts.ignoreErrors || false, opts.logger), {logQueries: true, logger: opts.logger})
        return formatSchema(schema, opts.inferRelations || false)
    },
    getTableStats: (application: string, url: DatabaseUrlParsed, id: TableId): Promise<TableStats> =>
        connect(application, url, getTableStats(id), {logQueries: true, logger}),
    getColumnStats: (application: string, url: DatabaseUrlParsed, ref: ColumnRef): Promise<ColumnStats> =>
        connect(application, url, getColumnStats(ref), {logQueries: true, logger}),
    query: (application: string, url: DatabaseUrlParsed, query: string, parameters: any[]): Promise<DatabaseQueryResults> =>
        connect(application, url, execQuery(query, parameters), {logQueries: true, logger}),
}
