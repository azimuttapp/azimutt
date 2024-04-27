import {Logger} from "@azimutt/utils";
import {Connector, Database, DatabaseUrlParsed, parseDatabaseUrl} from "@azimutt/models";
import {getConnector} from "@azimutt/gateway";

export async function launchAnalyze(url: string, logger: Logger): Promise<void> {
    const parsed: DatabaseUrlParsed = parseDatabaseUrl(url)
    const connector: Connector | undefined = getConnector(parsed)
    if (!connector) return Promise.reject('Invalid connector')
    const schema: Database = await connector.getSchema('azimutt-analyze', parsed, {logger})
    // TODO
}
