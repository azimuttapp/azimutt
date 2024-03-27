import {Logger} from "@azimutt/utils";

export const logger: Logger = {
    debug: (text: string): void => console.debug(text),
    log: (text: string): void => console.log(text),
    warn: (text: string): void => console.warn(text),
    error: (text: string): void => console.error(text)
}
export const application = 'azimutt-tests'
