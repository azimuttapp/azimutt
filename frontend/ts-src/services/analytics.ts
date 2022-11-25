import {Logger} from "./logger";
import {TrackingDetails} from "../types/ports";

export interface Analytics {
    trackPage: (name: string) => void
    trackEvent: (name: string, details?: TrackingDetails) => void
    trackError: (name: string, details?: TrackingDetails) => void
}

export type Plausible = (event: string, details?: {props: TrackingDetails}) => void

export class PlausibleAnalytics implements Analytics {
    private readonly plausible: Plausible

    constructor() {
        const plausible = (window as any).plausible
        this.plausible = plausible || function() { (plausible.q = plausible.q || []).push(arguments) }
    }

    trackPage = (name: string): void => { /* automatically tracked, do nothing */
    }
    trackEvent = (name: string, details?: TrackingDetails): void => {
        this.plausible(name, details ? {props: details} : details)
    }
    trackError = (name: string, details?: TrackingDetails): void => { /* don't track errors */
    }
}

export class LogAnalytics implements Analytics {
    constructor(private logger: Logger) {
    }

    trackPage = (name: string): void => this.logger.debug('analytics.page', name)
    trackEvent = (name: string, details?: TrackingDetails): void => this.logger.debug('analytics.event', name, details)
    trackError = (name: string, details?: TrackingDetails): void => this.logger.debug('analytics.error', name, details)
}
