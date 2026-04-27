import fastify, {FastifyInstance} from "fastify"
import cors from "@fastify/cors"
import routes from "./routes/index"
import {Config} from "./plugins/config";

export async function startServer(config: Config): Promise<FastifyInstance> {
    const server = fastify({
        ajv: {
            customOptions: {
                removeAdditional: 'all',
                coerceTypes: true,
                useDefaults: true,
                keywords: ['kind', 'modifier']
            }
        },
        logger: {
            level: process.env.LOG_LEVEL,
        },
    })
    process.on('unhandledRejection', exitOnError(process))
    process.on('SIGINT', closeAndExit(process, server, 'SIGINT'))
    process.on('SIGTERM', closeAndExit(process, server, 'SIGINT'))

    if (config.CORS_ALLOW_ORIGIN) {
        await server.register(cors, {origin: config.CORS_ALLOW_ORIGIN, credentials: true})

        // Chrome's Private Network Access (PNA) policy blocks public origins from fetching loopback/private addresses unless the server explicitly opts in.
        // The browser sends a preflight with `Access-Control-Request-Private-Network: true` and requires `Access-Control-Allow-Private-Network: true` in the response, independently of standard CORS.
        server.addHook('onSend', async (request, reply) => {
          if (request.headers['access-control-request-private-network'] === 'true') {
            reply.header('Access-Control-Allow-Private-Network', 'true')
          }
        })
    }
    await server.register(routes(config))
    await server.ready()

    const host = config.API_HOST
    const port = parseInt(config.API_PORT)
    await server.listen({host, port})
    return server
}

const exitOnError = (process: NodeJS.Process) => (err: string): void => {
    console.error(err)
    process.exit(1)
}

const closeAndExit = (process: NodeJS.Process, server: FastifyInstance, signal: string) => (): void => {
    server.close().then(err => {
        console.log(`close application on ${signal}`)
        process.exit(err ? 1 : 0)
    })
}
