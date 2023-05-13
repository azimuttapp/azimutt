import {Type} from '@sinclair/typebox';
import {FastifyPluginAsync} from 'fastify';
import {console, Logger} from "@azimutt/utils";
import {parseDatabaseUrl} from "@azimutt/database-types";
import {ErrorResponse, FailureResponse, GetSchemaParams, GetSchemaResponse} from "../schemas";
import {getConnector} from "../services/connector";

const routes: FastifyPluginAsync = async (server) => {
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

    server.get<{Querystring: GetSchemaParams, Reply: GetSchemaResponse | ErrorResponse | FailureResponse}>('/gateway/schema', {
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
            return await connector.getSchema('azimutt-gateway', url, {logger, schema: req.query.schema})
        } else {
            return res.status(400).send({error: `Not supported database: ${url.kind || url.full}`})
        }
    })
}

export default routes;
