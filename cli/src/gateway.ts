import {Logger} from "@azimutt/utils";
import {NodeEnv, startServer, track} from "@azimutt/gateway";

export async function launchGateway(logger: Logger): Promise<void> {
    logger.log('Starting Azimutt Gateway...')
    track('cli__gateway__start', {}, 'cli').then(() => {})
    await startServer({
        NODE_ENV: NodeEnv.production,
        LOG_LEVEL: 'info',
        API_HOST: 'localhost',
        API_PORT: '4177',
        CORS_ALLOW_ORIGIN: '*'
    })
}
