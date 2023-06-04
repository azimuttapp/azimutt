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
import {formatSchema, getSchema} from "./mysql";
import {execQuery} from "./query";

export const mysql: Connector = {
    name: 'MySQL',
    getSchema: async (application: string, url: DatabaseUrlParsed, opts: SchemaOpts): Promise<AzimuttSchema> => {
        const schema = await getSchema(application, url, opts.schema, opts.sampleSize || 100, opts.logger)
        return formatSchema(schema, opts.inferRelations || false)
    },
    getTableStats: (application: string, url: DatabaseUrlParsed, id: TableId): Promise<TableStats> =>
        Promise.reject(`'getTableStats' not implemented in MySQL`),
    getColumnStats: (application: string, url: DatabaseUrlParsed, ref: ColumnRef): Promise<ColumnStats> =>
        Promise.reject(`'getColumnStats' not implemented in MySQL`),
    query: (application: string, url: DatabaseUrlParsed, query: string, parameters: any[]): Promise<DatabaseQueryResults> =>
        execQuery(application, url, query, parameters),
}
