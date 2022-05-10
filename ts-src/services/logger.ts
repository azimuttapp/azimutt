import {Env} from "../types/basics";

export interface Logger {
    error(...args: any[]): void

    warn(...args: any[]): void

    info(...args: any[]): void

    log(...args: any[]): void

    debug(...args: any[]): void
}

export class ConsoleLogger implements Logger {
    constructor(private env: Env) {
    }

    error(...args: any[]): void {
        console.error(...args)
    }

    warn(...args: any[]): void {
        console.warn(...args)
    }

    info(...args: any[]): void {
        console.info(...args)
    }

    log(...args: any[]): void {
        console.log(...args)
    }

    debug(...args: any[]): void {
        if (this.env !== 'prod') {
            console.debug(...args)
        }
    }
}
