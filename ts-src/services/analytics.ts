import {Logger} from "./logger";
import {Splitbee} from "../types/window";

export interface Analytics {
    trackPage: (name: string) => void
    trackEvent: (name: string, details: object) => void
    trackError: (name: string, details: object) => void
}

export class SplitbeeAnalytics implements Analytics {
    static init(): Promise<SplitbeeAnalytics> {
        const waitSplitbee = (resolve: (r: SplitbeeAnalytics) => void, reject: (err: Error) => void, timeout: number) => {
            if (timeout <= 0) {
                reject(new Error('Splitbee not available'))
            } else if (window.splitbee) {
                resolve(new SplitbeeAnalytics(window.splitbee))
            } else {
                setTimeout(() => waitSplitbee(resolve, reject, timeout - 100), 100)
            }
        }
        return new Promise<SplitbeeAnalytics>((resolve, reject) => waitSplitbee(resolve, reject, 3000))
    }

    constructor(private splitbee: Splitbee) {
    }

    trackPage = (name: string): void => { /* automatically tracked, do nothing */
    }
    trackEvent = (name: string, details: object): void => {
        this.splitbee.track(name, details)
    }
    trackError = (name: string, details: object): void => { /* don't track errors in splitbee */
    }
}

export class LogAnalytics implements Analytics {
    constructor(private logger: Logger) {
    }

    trackPage = (name: string): void => this.logger.debug('analytics.page', name)
    trackEvent = (name: string, details: object): void => this.logger.debug('analytics.event', name, details)
    trackError = (name: string, details: object): void => this.logger.debug('analytics.error', name, details)
}
