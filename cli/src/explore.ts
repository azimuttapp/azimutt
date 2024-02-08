import open from "open";
import {Logger} from "@azimutt/utils";
import {launchGateway} from "./gateway.js";

export async function launchExplore(url: string, instance: string, logger: Logger): Promise<void> {
    // TODO: better error reporting when the import fails in Azimutt
    const azimuttUrl = `${instance}/create?database=${encodeURIComponent(url)}`
    // const azimuttUrl = `${instance}/embed?database-source=${encodeURIComponent(url)}&mode=full`
    // https://azimutt.app/embed?database-source=postgresql://postgres:postgres@localhost/azimutt_dev&mode=full
    // const azimuttUrl = `https://azimutt.app/create?database=${encodeURIComponent(url)}&gateway=http://localhost:4177`
    await launchGateway(logger)
    logger.log(`opening ${azimuttUrl}`)
    await open(azimuttUrl)
}
