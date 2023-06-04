import {TSchema, Type} from "@sinclair/typebox"
import {FastifyPluginAsync, FastifyReply} from "fastify"
import {RouteShorthandOptions} from "fastify/types/route"
import {Logger} from "@azimutt/utils"
import {Connector, DatabaseUrl, DatabaseUrlParsed, parseDatabaseUrl} from "@azimutt/database-types"
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

const application = 'azimutt-gateway'
const logger: Logger = {
    debug: (text: string) => console.debug(text),
    log: (text: string) => console.log(text),
    warn: (text: string) => console.warn(text),
    error: (text: string) => console.error(text)
}

const routes: FastifyPluginAsync = async (server) => {
    server.get('/', {schema: {response: {200: Type.Object({hello: Type.String()})}}}, async () => ({hello: 'world'}))
    server.get('/ping', async () => ({status: 200}))
    server.get('/health', async () => ({status: 200, version: '0.0.3'}))

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
    return withConnector(params.url, res, (url, conn) => conn.getSchema(application, url, {logger, schema: params.schema}))
}

function queryDatabase(params: DbQueryParams, res: FastifyReply): Promise<DbQueryResponse | FastifyReply> {
    return withConnector(params.url, res, (url, conn) => conn.query(application, url, params.query, []))
}

function getTableStats(params: GetTableStatsParams, res: FastifyReply): Promise<GetTableStatsResponse | FastifyReply> {
    const tableId = params.schema ? `${params.schema}.${params.table}` : params.table
    return withConnector(params.url, res, (url, conn) => conn.getTableStats(application, url, tableId))
}

function getColumnStats(params: GetColumnStatsParams, res: FastifyReply): Promise<GetColumnStatsResponse | FastifyReply> {
    const tableId = params.schema ? `${params.schema}.${params.table}` : params.table
    return withConnector(params.url, res, (url, conn) => conn.getColumnStats(application, url, {table: tableId, column: params.column}))
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
