import {Logger} from "@azimutt/utils";
import {buildConfig, NodeEnv, startServer, track} from "@azimutt/gateway";
import {version} from "./version.js";

export async function launchGateway(dataSourceUrls: string, logger: Logger): Promise<void> {
    logger.log('Starting Azimutt Gateway...')
    track('cli__gateway__start', {version}, 'cli').then(() => {})
    await startServer(buildConfig({
        NODE_ENV: NodeEnv.production,
        LOG_LEVEL: 'info',
        API_HOST: 'localhost',
        API_PORT: '4177',
        CORS_ALLOW_ORIGIN: '*',
        DATASOURCE_URLS: dataSourceUrls,
    }))
}
