import {Logger} from "./logger";
import * as Sentry from "@sentry/browser";
import {BrowserTracing} from "@sentry/tracing";
import {SentryConf} from "../conf";

export interface ErrLogger {
    trackError: (name: string, details?: object) => void
}

export class SentryErrLogger implements ErrLogger {
    constructor(conf: SentryConf) {
        Sentry.init(Object.assign({}, conf, {
            integrations: [new BrowserTracing()],
            tracesSampleRate: 1.0,
        }))
    }

    trackError = (name: string, details?: object): void => {
        // Sentry.captureMessage("Something went wrong")
        const data: object = details || {}
        Sentry.captureException(new Error(JSON.stringify({name, ...data})))
    }
}

export class LogErrLogger implements ErrLogger {
    constructor(private logger: Logger) {
    }

    trackError = (name: string, details?: object): void => this.logger.debug('error.track', name, details)
}
