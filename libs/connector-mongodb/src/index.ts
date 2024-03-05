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
import {execQuery, formatSchema, getSchema, MongodbSchemaOpts} from "./mongodb";
import {connect} from "./connect";

export * from "./mongodb"

export const mongodb: Connector = {
    name: 'MongoDb',
    getSchema: async (application: string, url: DatabaseUrlParsed, opts: ConnectorOps & SchemaOpts): Promise<AzimuttSchema> => {
        const schemaOpts: MongodbSchemaOpts = {
            logger: opts.logger,
            database: opts.schema,
            mixedCollection: opts.mixedCollection,
            sampleSize: withDefault(opts.sampleSize, 100),
            ignoreErrors: withDefault(opts.ignoreErrors, false)
        }
        const schema = await connect(application, url, getSchema(schemaOpts))
        return formatSchema(schema)
    },
    getTableStats: (application: string, url: DatabaseUrlParsed, id: TableId, opts: ConnectorOps): Promise<TableStats> =>
        Promise.reject(`'getTableStats' not implemented in MongoDb`),
    getColumnStats: (application: string, url: DatabaseUrlParsed, ref: ColumnRef, opts: ConnectorOps): Promise<ColumnStats> =>
        Promise.reject(`'getColumnStats' not implemented in MongoDb`),
    query: (application: string, url: DatabaseUrlParsed, query: string, parameters: any[], opts: ConnectorOps): Promise<DatabaseQueryResults> =>
        connect(application, url, execQuery(query, parameters)).then(r => ({
            query,
            columns: distinct(r.rows.flatMap(Object.keys)).map(name => ({name})),
            rows: r.rows.map(row => JSON.parse(JSON.stringify(row))) // serialize ObjectId & Date objects
        })),
}

function withDefault<T>(value: T | undefined, other: T): T {
    return value === undefined ? other : value
}
