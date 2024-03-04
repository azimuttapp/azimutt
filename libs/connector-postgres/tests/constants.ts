import {Logger} from "@azimutt/utils";
import {PostgresConnectOpts} from "../src/connect";

export const logger: Logger = {
    debug: (text: string): void => console.debug(text),
    log: (text: string): void => console.log(text),
    warn: (text: string): void => console.warn(text),
    error: (text: string): void => console.error(text)
}
export const opts: PostgresConnectOpts = {logger, logQueries: true}
export const application = 'azimutt-tests'
