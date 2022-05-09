import {loadScript} from "./utils";
import {Sentry} from "./types/sentry";

export interface ErrLogger {
    trackError: (name: string, details: object) => void
}

export class SentryErrLogger implements ErrLogger {
    static init(): Promise<SentryErrLogger> {
        // see https://sentry.io
        // initial: https://js.sentry-cdn.com/268b122ecafb4f20b6316b87246e509c.min.js
        return loadScript('/assets/sentry-268b122ecafb4f20b6316b87246e509c.min.js').then(() => new SentryErrLogger(window.Sentry))
    }

    constructor(private sentry: Sentry) {
    }

    trackError = (name: string, details: object): void => this.sentry.captureException(new Error(JSON.stringify({name, ...details})))
}

export class ConsoleErrLogger implements ErrLogger {
    trackError = (name: string, details: object): void => console.log('error.track', name, details)
}
