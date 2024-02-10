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
import {formatSchema, getSchema} from "./snowflake";
import {getColumnStats, getTableStats} from "./stats";

export const snowflake: Connector = {
    name: 'Snowflake',
    getSchema: async (application: string, url: DatabaseUrlParsed, opts: SchemaOpts): Promise<AzimuttSchema> => {
        const schema = await connect(application, url, getSchema(opts.schema, opts.sampleSize || 100, opts.ignoreErrors || false, opts.logger))
        return formatSchema(schema, opts.inferRelations || false)
    },
    getTableStats: (application: string, url: DatabaseUrlParsed, id: TableId): Promise<TableStats> =>
        Promise.reject('Not implemented'), // connect(application, url, getTableStats(id)),
    getColumnStats: (application: string, url: DatabaseUrlParsed, ref: ColumnRef): Promise<ColumnStats> =>
        Promise.reject('Not implemented'), // connect(application, url, getColumnStats(ref)),
    query: (application: string, url: DatabaseUrlParsed, query: string, parameters: any[]): Promise<DatabaseQueryResults> =>
        Promise.reject('Not implemented'), // connect(application, url, execQuery(query, parameters)),
}
