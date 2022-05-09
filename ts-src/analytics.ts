import {Splitbee} from "./types/splitbee";

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

export class ConsoleAnalytics implements Analytics {
    trackPage = (name: string): void => console.log('analytics.page', name)
    trackEvent = (name: string, details: object): void => console.log('analytics.event', name, details)
    trackError = (name: string, details: object): void => console.log('analytics.error', name, details)
}
