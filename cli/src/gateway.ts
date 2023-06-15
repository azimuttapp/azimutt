import {Logger} from "@azimutt/utils";
import {NodeEnv, startServer} from "@azimutt/gateway";

export async function launchGateway(logger: Logger): Promise<void> {
    logger.log('Starting Azimutt Gateway...')
    await startServer({
        NODE_ENV: NodeEnv.production,
        LOG_LEVEL: 'info',
        API_HOST: 'localhost',
        API_PORT: '4177',
        CORS_ALLOW_ORIGIN: '*'
    })
}

export {availableConnectors} from "@azimutt/gateway/out/services/connector";
