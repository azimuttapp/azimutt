import {distinct} from "@azimutt/utils";
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
import {CouchbaseSchemaOpts, execQuery, formatSchema, getSchema} from "./couchbase";
import {connect} from "./connect";

export * from "./couchbase"

export const couchbase: Connector = {
    name: 'Couchbase',
    getSchema: async (application: string, url: DatabaseUrlParsed, opts: ConnectorOps & SchemaOpts): Promise<AzimuttSchema> => {
        const schemaOpts: CouchbaseSchemaOpts = {
            logger: opts.logger,
            bucket: opts.schema,
            mixedCollection: opts.mixedCollection,
            sampleSize: withDefault(opts.sampleSize, 100),
            ignoreErrors: withDefault(opts.ignoreErrors, false)
        }
        const schema = await connect(application, url, getSchema(schemaOpts))
        return formatSchema(schema)
    },
    getTableStats: (application: string, url: DatabaseUrlParsed, id: TableId, opts: ConnectorOps): Promise<TableStats> =>
        Promise.reject(`'getTableStats' not implemented in Couchbase`),
    getColumnStats: (application: string, url: DatabaseUrlParsed, ref: ColumnRef, opts: ConnectorOps): Promise<ColumnStats> =>
        Promise.reject(`'getColumnStats' not implemented in Couchbase`),
    query: (application: string, url: DatabaseUrlParsed, query: string, parameters: any[], opts: ConnectorOps): Promise<DatabaseQueryResults> =>
        connect(application, url, execQuery(query, parameters)).then(r => ({
            query,
            columns: distinct(r.rows.flatMap(Object.keys)).map(name => ({name})),
            rows: r.rows
        }))
}

function withDefault<T>(value: T | undefined, other: T): T {
    return value === undefined ? other : value
}
