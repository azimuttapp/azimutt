import {Type} from "@sinclair/typebox"
import {FastifyPluginAsync} from "fastify"
import {console, Logger} from "@azimutt/utils"
import {parseDatabaseUrl} from "@azimutt/database-types"
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
    GetTableStatsResponse
} from "../schemas.js"
import {getConnector} from "../services/connector.js"

const routes: FastifyPluginAsync = async (server) => {
    const application = 'azimutt-gateway'
    const logger: Logger = console

    server.get('/ping', async () => ({status: 200}))

    server.get('/', {
        schema: {
            response: {
                200: Type.Object({
                    hello: Type.String(),
                }),
            },
        },
    }, async () => ({hello: 'world'}))

    server.get<{
        Querystring: GetSchemaParams,
        Reply: GetSchemaResponse | ErrorResponse | FailureResponse
    }>('/gateway/schema', {
        schema: {
            querystring: GetSchemaParams,
            response: {
                200: GetSchemaResponse,
                400: ErrorResponse,
                500: FailureResponse,
            },
        },
    }, async (req, res) => {
        const url = parseDatabaseUrl(req.query.url)
        const connector = getConnector(url)
        if (connector) {
            return await connector.getSchema(application, url, {logger, schema: req.query.schema})
        } else {
            return res.status(400).send({error: `Not supported database: ${url.kind || url.full}`})
        }
    })

    server.get<{
        Querystring: DbQueryParams,
        Reply: DbQueryResponse | ErrorResponse | FailureResponse
    }>('/gateway/query', {
        schema: {
            querystring: DbQueryParams,
            response: {
                200: DbQueryResponse,
                400: ErrorResponse,
                500: FailureResponse,
            },
        },
    }, async (req, res) => {
        const url = parseDatabaseUrl(req.query.url)
        const connector = getConnector(url)
        if (connector) {
            return await connector.query(application, url, req.query.query, [])
        } else {
            return res.status(400).send({error: `Not supported database: ${url.kind || url.full}`})
        }
    })

    server.get<{
        Querystring: GetTableStatsParams,
        Reply: GetTableStatsResponse | ErrorResponse | FailureResponse
    }>('/gateway/table-stats', {
        schema: {
            querystring: GetTableStatsParams,
            response: {
                200: GetTableStatsResponse,
                400: ErrorResponse,
                500: FailureResponse,
            },
        },
    }, async (req, res) => {
        const url = parseDatabaseUrl(req.query.url)
        const connector = getConnector(url)
        const tableId = req.query.schema ? `${req.query.schema}.${req.query.table}` : req.query.table
        if (connector) {
            return await connector.getTableStats(application, url, tableId)
        } else {
            return res.status(400).send({error: `Not supported database: ${url.kind || url.full}`})
        }
    })

    server.get<{
        Querystring: GetColumnStatsParams,
        Reply: GetColumnStatsResponse | ErrorResponse | FailureResponse
    }>('/gateway/column-stats', {
        schema: {
            querystring: GetColumnStatsParams,
            response: {
                200: GetColumnStatsResponse,
                400: ErrorResponse,
                500: FailureResponse,
            },
        },
    }, async (req, res) => {
        const url = parseDatabaseUrl(req.query.url)
        const connector = getConnector(url)
        const tableId = req.query.schema ? `${req.query.schema}.${req.query.table}` : req.query.table
        if (connector) {
            return await connector.getColumnStats(application, url, {table: tableId, column: req.query.column})
        } else {
            return res.status(400).send({error: `Not supported database: ${url.kind || url.full}`})
        }
    })
}

export default routes
