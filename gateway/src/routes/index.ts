import process from "process";
import {TSchema} from "@sinclair/typebox"
import {FastifyPluginAsync, FastifyReply} from "fastify"
import {RouteShorthandOptions} from "fastify/types/route"
import {Logger, removeUndefined} from "@azimutt/utils"
import {
    AttributeRef,
    columnStatsToLegacy,
    Connector,
    databaseToLegacy,
    DatabaseUrl,
    DatabaseUrlParsed,
    EntityRef,
    parseDatabaseUrl,
    queryResultsToLegacy,
    tableStatsToLegacy
} from "@azimutt/models"
import {version} from "../version";
import {Config} from "../plugins/config";
import {
    ColumnStatsResponse,
    DbColumnStatsParams,
    DbQueryParams,
    DbSchemaParams,
    DbTableStatsParams,
    DsColumnStatsParams,
    DsQueryParams,
    DsSchemaParams,
    DsTableStatsParams,
    ErrorResponse,
    FailureResponse,
    ParseUrlParams,
    ParseUrlResponse,
    QueryResponse,
    SchemaResponse,
    TableStatsResponse
} from "../schemas"
import {getConnector} from "../services/connector"
import {track} from "../services/tracking";

const application = 'azimutt-gateway'
const logger: Logger = {
    debug: (text: string) => console.debug(text),
    log: (text: string) => console.log(text),
    warn: (text: string) => console.warn(text),
    error: (text: string) => console.error(text)
}

const routes: (config: Config) => FastifyPluginAsync = (config: Config) => async (server) => {
    server.get('/', async () => ({status: 200, version}))
    server.get('/ping', async () => ({status: 200}))
    server.get('/health', async () => ({status: 200, version}))
    server.get('/status', async () => ({status: 200, version, node: process.versions.node}))

    server.get<Get<undefined, ParseUrlParams, ParseUrlResponse>>('/gateway/parse-url', get(undefined, ParseUrlParams, ParseUrlResponse), async req => parseDatabaseUrl(req.query.url))
    server.post<Post<undefined, undefined, ParseUrlParams, ParseUrlResponse>>('/gateway/parse-url', post(undefined, undefined, ParseUrlParams, ParseUrlResponse), async req => parseDatabaseUrl(req.body.url))
    server.get<Get<{slug: string}, undefined, {status: number}>>('/gateway/data-sources/:slug', async () => ({status: 200}))

    server.get<Get<undefined, DbSchemaParams, SchemaResponse>>('/gateway/schema', get(undefined, DbSchemaParams, SchemaResponse), async (req, res) => await getDatabaseSchema(req.query, res))
    server.post<Post<undefined, undefined, DbSchemaParams, SchemaResponse>>('/gateway/schema', post(undefined, undefined, DbSchemaParams, SchemaResponse), async (req, res) => await getDatabaseSchema(req.body, res))
    server.get<Get<{slug: string}, DsSchemaParams, SchemaResponse>>('/gateway/data-sources/:slug/schema', get(undefined, DsSchemaParams, SchemaResponse), async (req, res) => await withDatasource(req.params.slug, res, url => getDatabaseSchema({...req.query, url}, res)))
    server.post<Post<{slug: string}, undefined, DsSchemaParams, SchemaResponse>>('/gateway/data-sources/:slug/schema', post(undefined, undefined, DsSchemaParams, SchemaResponse), async (req, res) => await withDatasource(req.params.slug, res, url => getDatabaseSchema({...req.body, url}, res)))

    server.get<Get<undefined, DbQueryParams, QueryResponse>>('/gateway/query', get(undefined, DbQueryParams, QueryResponse), async (req, res) => await queryDatabase(req.query, res))
    server.post<Post<undefined, undefined, DbQueryParams, QueryResponse>>('/gateway/query', post(undefined, undefined, DbQueryParams, QueryResponse), async (req, res) => await queryDatabase(req.body, res))
    server.get<Get<{slug: string}, DsQueryParams, QueryResponse>>('/gateway/data-sources/:slug/query', get(undefined, DsQueryParams, QueryResponse), async (req, res) => await withDatasource(req.params.slug, res, url => queryDatabase({...req.query, url}, res)))
    server.post<Post<{slug: string}, undefined, DsQueryParams, QueryResponse>>('/gateway/data-sources/:slug/query', post(undefined, undefined, DsQueryParams, QueryResponse), async (req, res) => await withDatasource(req.params.slug, res, url => queryDatabase({...req.body, url}, res)))

    server.get<Get<undefined, DbTableStatsParams, TableStatsResponse>>('/gateway/table-stats', get(undefined, DbTableStatsParams, TableStatsResponse), async (req, res) => await getTableStats(req.query, res))
    server.post<Post<undefined, undefined, DbTableStatsParams, TableStatsResponse>>('/gateway/table-stats', post(undefined, undefined, DbTableStatsParams, TableStatsResponse), async (req, res) => await getTableStats(req.body, res))
    server.get<Get<{slug: string}, DsTableStatsParams, TableStatsResponse>>('/gateway/data-sources/:slug/table-stats', get(undefined, DsTableStatsParams, TableStatsResponse), async (req, res) => await withDatasource(req.params.slug, res, url => getTableStats({...req.query, url}, res)))
    server.post<Post<{slug: string}, undefined, DsTableStatsParams, TableStatsResponse>>('/gateway/data-sources/:slug/table-stats', post(undefined, undefined, DsTableStatsParams, TableStatsResponse), async (req, res) => await withDatasource(req.params.slug, res, url => getTableStats({...req.body, url}, res)))

    server.get<Get<undefined, DbColumnStatsParams, ColumnStatsResponse>>('/gateway/column-stats', get(undefined, DbColumnStatsParams, ColumnStatsResponse), async (req, res) => await getColumnStats(req.query, res))
    server.post<Post<undefined, undefined, DbColumnStatsParams, ColumnStatsResponse>>('/gateway/column-stats', post(undefined, undefined, DbColumnStatsParams, ColumnStatsResponse), async (req, res) => await getColumnStats(req.body, res))
    server.get<Get<{slug: string}, DsColumnStatsParams, ColumnStatsResponse>>('/gateway/data-sources/:slug/column-stats', get(undefined, DsColumnStatsParams, ColumnStatsResponse), async (req, res) => await withDatasource(req.params.slug, res, url => getColumnStats({...req.query, url}, res)))
    server.post<Post<{slug: string}, undefined, DsColumnStatsParams, ColumnStatsResponse>>('/gateway/data-sources/:slug/column-stats', post(undefined, undefined, DsColumnStatsParams, ColumnStatsResponse), async (req, res) => await withDatasource(req.params.slug, res, url => getColumnStats({...req.body, url}, res)))

    buildDataSources(config)
}

function getDatabaseSchema(params: DbSchemaParams, res: FastifyReply): Promise<SchemaResponse | FastifyReply> {
    return withConnector(params.url, res, (url, conn) => {
        track('gateway__database__get_schema', {version, database: url.kind}, 'gateway').then(() => {})
        const urlOptions = url.options || {}
        return conn.getSchema(buildApp(params.user), url, {
            logger,
            logQueries: urlOptions['log-queries'] === 'true',
            database: params.database || urlOptions['database'],
            catalog: params.catalog || urlOptions['catalog'],
            schema: params.schema || urlOptions['schema'],
            entity: params.entity || urlOptions['entity'],
            sampleSize: undefined,
            inferMixedJson: urlOptions['discriminator'],
            inferJsonAttributes: urlOptions['schema-only'] !== 'true',
            inferPolymorphicRelations: urlOptions['schema-only'] !== 'true',
            inferRelationsFromJoins: urlOptions['schema-only'] !== 'true',
            inferPii: urlOptions['schema-only'] !== 'true',
            inferRelations: true,
            ignoreErrors: urlOptions['ignore-errors'] === 'true'
        }).then(databaseToLegacy)
    })
}

function queryDatabase(params: DbQueryParams, res: FastifyReply): Promise<QueryResponse | FastifyReply> {
    return withConnector(params.url, res, (url, conn) => conn.execute(buildApp(params.user), url, params.query, [], {logger}).then(queryResultsToLegacy))
}

function getTableStats(params: DbTableStatsParams, res: FastifyReply): Promise<TableStatsResponse | FastifyReply> {
    const ref: EntityRef = {schema: params.schema, entity: params.table}
    return withConnector(params.url, res, (url, conn) => conn.getEntityStats(buildApp(params.user), url, ref, {logger}).then(tableStatsToLegacy))
}

function getColumnStats(params: DbColumnStatsParams, res: FastifyReply): Promise<ColumnStatsResponse | FastifyReply> {
    const ref: AttributeRef = {schema: params.schema, entity: params.table, attribute: [params.column]}
    return withConnector(params.url, res, (url, conn) => conn.getAttributeStats(buildApp(params.user), url, ref, {logger}).then(columnStatsToLegacy))
}

async function withConnector<T>(url: DatabaseUrl, res: FastifyReply, exec: (url: DatabaseUrlParsed, conn: Connector) => Promise<T>): Promise<T | FastifyReply> {
    const parsedUrl = parseDatabaseUrl(url)
    const connector = getConnector(parsedUrl)
    if (connector) {
        return await exec(parsedUrl, connector)
    } else {
        return res.status(400).send({error: `Not supported database: ${parsedUrl.kind || url}`})
    }
}

const dataSources: {[slug: string]: DatabaseUrl} = {}

function buildDataSources(config: Config): void {
    // urls from env
    (config.DATASOURCE_URLS || '').split(',').map(url => url.trim()).filter(url => !!url).forEach(url => {
        const parsed = parseDatabaseUrl(url.trim())
        if (parsed.db) {
            dataSources[parsed.db] = parsed.full
        }
    })
    // urls from file
    // TODO: must define format, json? text?

    const slugs = Object.keys(dataSources)
    if (slugs.length > 0) {
        console.log('Gateway data-sources:')
        slugs.forEach(slug => console.log(`  - ${config.API_HOST}:${config.API_PORT}/gateway/data-sources/${slug}`))
    }
}

async function withDatasource<T>(datasource: string, res: FastifyReply, exec: (url: DatabaseUrl) => Promise<T>): Promise<T | FastifyReply> {
    const url = dataSources[datasource]
    if (url) {
        return await exec(url)
    } else {
        return res.status(400).send({error: `Unknown datasource: ${datasource}`})
    }
}

function buildApp(user: string | undefined): string {
    return user ? `${application}:${user}` : application
}

type Get<Params = undefined, Query = undefined, Response = undefined> = {
    Params: Params
    Querystring: Query
    Reply: Response | ErrorResponse | FailureResponse
}

function get(params: TSchema | undefined, query: TSchema | undefined, response: TSchema): RouteShorthandOptions {
    return {
        schema: removeUndefined({
            params: params,
            querystring: query,
            response: {
                200: response,
                400: ErrorResponse,
                500: FailureResponse,
            },
        }),
    }
}

type Post<Params = undefined, Query = undefined, Body = undefined, Response = undefined> = {
    Params: Params
    Querystring: Query
    Body: Body,
    Reply: Response | ErrorResponse | FailureResponse
}

function post(params: TSchema | undefined, query: TSchema | undefined, body: TSchema | undefined, response: TSchema): RouteShorthandOptions {
    return {
        schema: removeUndefined({
            params: params,
            querystring: query,
            body: body,
            response: {
                200: response,
                400: ErrorResponse,
                500: FailureResponse,
            },
        }),
    }
}

export default routes
