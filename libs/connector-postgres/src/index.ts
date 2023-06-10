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
import {formatSchema, getSchema} from "./postgres";
import {getColumnStats, getTableStats} from "./stats";

export const postgres: Connector = {
    name: 'PostgreSQL',
    getSchema: async (application: string, url: DatabaseUrlParsed, opts: SchemaOpts): Promise<AzimuttSchema> => {
        const schema = await connect(application, url, getSchema(opts.schema, opts.sampleSize || 100, opts.logger))
        return formatSchema(schema, opts.inferRelations || false)
    },
    getTableStats: (application: string, url: DatabaseUrlParsed, id: TableId): Promise<TableStats> =>
        connect(application, url, getTableStats(id)),
    getColumnStats: (application: string, url: DatabaseUrlParsed, ref: ColumnRef): Promise<ColumnStats> =>
        connect(application, url, getColumnStats(ref)),
    query: (application: string, url: DatabaseUrlParsed, query: string, parameters: any[]): Promise<DatabaseQueryResults> =>
        connect(application, url, execQuery(query, parameters)),
}
