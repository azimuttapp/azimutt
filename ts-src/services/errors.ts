import {Logger} from "./logger";
import {Sentry} from "../types/window";
import {Utils} from "../utils/utils";

export interface ErrLogger {
    trackError: (name: string, details: object) => void
}

export class SentryErrLogger implements ErrLogger {
    static init(): Promise<SentryErrLogger> {
        // see https://sentry.io
        // initial: https://js.sentry-cdn.com/268b122ecafb4f20b6316b87246e509c.min.js
        return Utils.loadScript('/assets/sentry-268b122ecafb4f20b6316b87246e509c.min.js').then(() => new SentryErrLogger(window.Sentry))
    }

    constructor(private sentry: Sentry) {
    }

    trackError = (name: string, details: object): void => this.sentry.captureException(new Error(JSON.stringify({name, ...details})))
}

export class LogErrLogger implements ErrLogger {
    constructor(private logger: Logger) {
    }

    trackError = (name: string, details: object): void => this.logger.debug('error.track', name, details)
}
