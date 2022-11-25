import {Logger} from "./logger";
import {TrackingDetails} from "../types/ports";

export interface Analytics {
    trackPage: (name: string) => void
    trackEvent: (name: string, details?: TrackingDetails) => void
    trackError: (name: string, details?: TrackingDetails) => void
}

export type Plausible = (event: string, details?: { props: TrackingDetails }) => void

export class PlausibleAnalytics implements Analytics {
    private readonly buffer: { name: string, details?: TrackingDetails }[] = []
    trackPage = (name: string): void => { /* automatically tracked, do nothing */
    }
    trackEvent = (name: string, details?: TrackingDetails): void => {
        if (window.plausible) {
            window.plausible(name, details ? {props: details} : details)
        } else {
            this.buffer.length === 0 && setTimeout(() => this.sendBuffer(), 500)
            this.buffer.push({name, details})
        }
    }
    trackError = (name: string, details?: TrackingDetails): void => { /* don't track errors */
    }

    private sendBuffer = (): void => {
        if (window.plausible) {
            this.buffer.splice(0, this.buffer.length).forEach(({name, details}) => this.trackEvent(name, details))
        } else {
            setTimeout(() => this.sendBuffer(), 500)
        }
    }
}

export class LogAnalytics implements Analytics {
    constructor(private logger: Logger) {
    }

    trackPage = (name: string): void => this.logger.debug('analytics.page', name)
    trackEvent = (name: string, details?: TrackingDetails): void => this.logger.debug('analytics.event', name, details)
    trackError = (name: string, details?: TrackingDetails): void => this.logger.debug('analytics.error', name, details)
}
