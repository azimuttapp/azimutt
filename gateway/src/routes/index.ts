import process from "process";
import {TSchema} from "@sinclair/typebox"
import {FastifyPluginAsync, FastifyReply} from "fastify"
import {RouteShorthandOptions} from "fastify/types/route"
import {Logger} from "@azimutt/utils"
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
import {
    DbQueryParams,
    DbQueryResponse,
    ErrorResponse,
    FailureResponse,
    GetColumnStatsParams,
    GetColumnStatsResponse,
    GetSchemaParams,
    GetSchemaResponse,
    GetTableStatsParams,
    GetTableStatsResponse,
    ParseUrlParams,
    ParseUrlResponse
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

const routes: FastifyPluginAsync = async (server) => {
    server.get('/', async () => ({status: 200, version}))
    server.get('/ping', async () => ({status: 200}))
    server.get('/health', async () => ({status: 200, version}))
    server.get('/status', async () => ({status: 200, version, package: process.env.npm_package_version, node: process.versions.node}))

    server.get<Get<ParseUrlParams, ParseUrlResponse>>('/gateway/parse-url', get(ParseUrlParams, ParseUrlResponse), async req => parseDatabaseUrl(req.query.url))
    server.post<Post<ParseUrlParams, ParseUrlResponse>>('/gateway/parse-url', post(ParseUrlParams, ParseUrlResponse), async req => parseDatabaseUrl(req.body.url))

    server.get<Get<GetSchemaParams, GetSchemaResponse>>('/gateway/schema', get(GetSchemaParams, GetSchemaResponse), async (req, res) => await getDatabaseSchema(req.query, res))
    server.post<Post<GetSchemaParams, GetSchemaResponse>>('/gateway/schema', post(GetSchemaParams, GetSchemaResponse), async (req, res) => await getDatabaseSchema(req.body, res))

    server.get<Get<DbQueryParams, DbQueryResponse>>('/gateway/query', get(DbQueryParams, DbQueryResponse), async (req, res) => await queryDatabase(req.query, res))
    server.post<Post<DbQueryParams, DbQueryResponse>>('/gateway/query', post(DbQueryParams, DbQueryResponse), async (req, res) => await queryDatabase(req.body, res))

    server.get<Get<GetTableStatsParams, GetTableStatsResponse>>('/gateway/table-stats', get(GetTableStatsParams, GetTableStatsResponse), async (req, res) => await getTableStats(req.query, res))
    server.post<Post<GetTableStatsParams, GetTableStatsResponse>>('/gateway/table-stats', post(GetTableStatsParams, GetTableStatsResponse), async (req, res) => await getTableStats(req.body, res))

    server.get<Get<GetColumnStatsParams, GetColumnStatsResponse>>('/gateway/column-stats', get(GetColumnStatsParams, GetColumnStatsResponse), async (req, res) => await getColumnStats(req.query, res))
    server.post<Post<GetColumnStatsParams, GetColumnStatsResponse>>('/gateway/column-stats', post(GetColumnStatsParams, GetColumnStatsResponse), async (req, res) => await getColumnStats(req.body, res))
}

function getDatabaseSchema(params: GetSchemaParams, res: FastifyReply): Promise<GetSchemaResponse | FastifyReply> {
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

function queryDatabase(params: DbQueryParams, res: FastifyReply): Promise<DbQueryResponse | FastifyReply> {
    return withConnector(params.url, res, (url, conn) => conn.execute(buildApp(params.user), url, params.query, [], {logger}).then(queryResultsToLegacy))
}

function getTableStats(params: GetTableStatsParams, res: FastifyReply): Promise<GetTableStatsResponse | FastifyReply> {
    const ref: EntityRef = {schema: params.schema, entity: params.table}
    return withConnector(params.url, res, (url, conn) => conn.getEntityStats(buildApp(params.user), url, ref, {logger}).then(tableStatsToLegacy))
}

function getColumnStats(params: GetColumnStatsParams, res: FastifyReply): Promise<GetColumnStatsResponse | FastifyReply> {
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

function buildApp(user: string | undefined): string {
    return user ? `${application}:${user}` : application
}

type Get<Params, Response> = {
    Querystring: Params,
    Reply: Response | ErrorResponse | FailureResponse
}

function get(params: TSchema, response: TSchema): RouteShorthandOptions {
    return {
        schema: {
            querystring: params,
            response: {
                200: response,
                400: ErrorResponse,
                500: FailureResponse,
            },
        },
    }
}

type Post<Params, Response> = {
    Body: Params,
    Reply: Response | ErrorResponse | FailureResponse
}

function post(params: TSchema, response: TSchema): RouteShorthandOptions {
    return {
        schema: {
            body: params,
            response: {
                200: response,
                400: ErrorResponse,
                500: FailureResponse,
            },
        },
    }
}

export default routes
