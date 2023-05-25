import fastify from "fastify"
import cors from "@fastify/cors"
import config from "./plugins/config.js"
import routes from "./routes/index.js"

const server = fastify({
    ajv: {
        customOptions: {
            removeAdditional: "all",
            coerceTypes: true,
            useDefaults: true,
            keywords: ['kind', 'modifier']
        }
    },
    logger: {
        level: process.env.LOG_LEVEL,
    },
})

await server.register(config)
server.config.CORS_ALLOW_ORIGIN && await server.register(cors, {origin: server.config.CORS_ALLOW_ORIGIN, credentials: true})
await server.register(routes)
await server.ready()

export default server
