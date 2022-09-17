import {Env} from "../utils/env";

export class Logger {
    error(...args: any[]): void {
        throw 'Not implemented'
    }

    warn(...args: any[]): void {
        throw 'Not implemented'
    }

    info(...args: any[]): void {
        throw 'Not implemented'
    }

    log(...args: any[]): void {
        throw 'Not implemented'
    }

    debug(...args: any[]): void {
        throw 'Not implemented'
    }

    disableDebug(): Logger {
        return new ProxyLogger(this, LoggerLevel.debug)
    }
}

export class ConsoleLogger extends Logger {
    constructor(private env: Env) {
        super()
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
        if (this.env !== Env.prod) {
            console.debug(...args)
        }
    }
}

export type LoggerLevel = 'error' | 'warn' | 'info' | 'log' | 'debug'
export const LoggerLevel: { [key in LoggerLevel]: key } = {
    error: 'error',
    warn: 'warn',
    info: 'info',
    log: 'log',
    debug: 'debug'
}

export class ProxyLogger extends Logger {
    constructor(private underlying: Logger, private disabled: LoggerLevel) {
        super()
    }

    error(...args: any[]): void {
        if (this.disabled !== LoggerLevel.error) {
            this.underlying.error(...args)
        }
    }

    warn(...args: any[]): void {
        if (this.disabled !== LoggerLevel.warn) {
            this.underlying.warn(...args)
        }
    }

    info(...args: any[]): void {
        if (this.disabled !== LoggerLevel.info) {
            this.underlying.info(...args)
        }
    }

    log(...args: any[]): void {
        if (this.disabled !== LoggerLevel.log) {
            this.underlying.log(...args)
        }
    }

    debug(...args: any[]): void {
        if (this.disabled !== LoggerLevel.debug) {
            this.underlying.debug(...args)
        }
    }
}
