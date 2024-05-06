import open from "open";
import {Logger} from "@azimutt/utils";
import {DatabaseUrlParsed, parseDatabaseUrl} from "@azimutt/models";
import {NodeEnv, startServer, track} from "@azimutt/gateway";

export async function launchExplore(url: string, instance: string, logger: Logger): Promise<void> {
    // TODO: better error reporting when the import fails in Azimutt
    const parsed: DatabaseUrlParsed = parseDatabaseUrl(url)
    track('cli__explore__run', {database: parsed.kind}, 'cli').then(() => {})
    const azimuttUrl = `${instance}/create?database=${encodeURIComponent(url)}`
    // const azimuttUrl = `${instance}/embed?database-source=${encodeURIComponent(url)}&mode=full`
    // https://azimutt.app/embed?database-source=postgresql://postgres:postgres@localhost/azimutt_dev&mode=full
    // const azimuttUrl = `https://azimutt.app/create?database=${encodeURIComponent(url)}&gateway=http://localhost:4177`
    await startServer({
        NODE_ENV: NodeEnv.production,
        LOG_LEVEL: 'info',
        API_HOST: 'localhost',
        API_PORT: '4177',
        CORS_ALLOW_ORIGIN: '*'
    })
    logger.log(`opening ${azimuttUrl}`)
    await open(azimuttUrl)
}
