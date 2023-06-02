import {NodeEnv, startServer} from "@azimutt/gateway";

export async function launchGateway(): Promise<void> {
    await startServer({
        NODE_ENV: NodeEnv.production,
        LOG_LEVEL: 'info',
        API_HOST: 'localhost',
        API_PORT: '4177',
        CORS_ALLOW_ORIGIN: 'http://localhost:4000'
    })
}
