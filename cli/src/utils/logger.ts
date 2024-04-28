import chalk from "chalk";
import {Logger} from "@azimutt/utils";

export const logger: Logger = {
    debug: (text: string): void => console.debug(chalk.cyan(text)),
    log: (text: string): void => console.log(text),
    warn: (text: string): void => console.warn(chalk.yellow(text)),
    error: (text: string): void => console.error(chalk.red(text))
}

export const loggerNoOp: Logger = {
    debug: (text: string): void => {},
    log: (text: string): void => {},
    warn: (text: string): void => {},
    error: (text: string): void => {}
}
