import "dotenv/config"
import {Static, Type} from "@sinclair/typebox"
import Ajv from "ajv"

export enum NodeEnv {
    development = "development",
    test = "test",
    production = "production",
}

const ConfigSchema = Type.Strict(
    Type.Object({
        NODE_ENV: Type.Enum(NodeEnv),
        LOG_LEVEL: Type.String(),
        API_HOST: Type.String(),
        API_PORT: Type.String(),
        CORS_ALLOW_ORIGIN: Type.Optional(Type.String()),
        DATASOURCE_URLS: Type.Optional(Type.String()), // db urls separated with a comma, data-sources stored inside the gateway
    })
)

const ajv = new Ajv({
    allErrors: true,
    removeAdditional: true,
    useDefaults: true,
    coerceTypes: true,
    allowUnionTypes: true,
})

export type Config = Static<typeof ConfigSchema>

export const configFromEnv = (): Config => {
    const env = process.env
    return buildConfig({
        NODE_ENV: env.NODE_ENV,
        LOG_LEVEL: env.LOG_LEVEL,
        API_HOST: env.API_HOST,
        API_PORT: env.API_PORT,
        CORS_ALLOW_ORIGIN: env.CORS_ALLOW_ORIGIN,
        DATASOURCE_URLS: env.DATASOURCE_URLS,
    } as Config)
}

export const buildConfig = (config: Config): Config => {
    const validate = ajv.compile(ConfigSchema)
    if (validate(config)) {
        return config
    } else {
        throw new Error('invalid configuration - ' + JSON.stringify(validate.errors, null, 2))
    }
}

declare module "fastify" {
    interface FastifyInstance {
        config: Config
    }
}
