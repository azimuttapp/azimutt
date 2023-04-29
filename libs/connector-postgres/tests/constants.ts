import {Logger} from "@azimutt/utils";
import {DatabaseUrlParsed, parseDatabaseUrl} from "@azimutt/database-types";

export const logger: Logger = {
    debug: (text: string): void => console.debug(text),
    log: (text: string): void => console.log(text),
    warn: (text: string): void => console.warn(text),
    error: (text: string): void => console.error(text)
}
export const url: DatabaseUrlParsed = parseDatabaseUrl('postgresql://postgres:postgres@localhost:5432/azimutt_dev')
