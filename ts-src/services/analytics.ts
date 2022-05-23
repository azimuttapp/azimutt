import {Logger} from "./logger";
import splitbee from '@splitbee/web';
import {Data} from "../types/elm";
import {Profile} from "../types/profile";

export interface Analytics {
    trackPage: (name: string) => void
    trackEvent: (name: string, details?: Data) => void
    trackError: (name: string, details?: Data) => void
    login: (user: Profile) => void
    logout: () => void
}

export class SplitbeeAnalytics implements Analytics {
    constructor() {
        splitbee.init({
            scriptUrl: "https://azimutt.app/bee.js",
            apiUrl: "https://azimutt.app/_hive"
        })
    }

    trackPage = (name: string): void => { /* automatically tracked, do nothing */
    }
    trackEvent = (name: string, details?: Data): void => {
        splitbee.track(name, details)
    }
    trackError = (name: string, details?: Data): void => { /* don't track errors in splitbee */
    }
    login = (user: Profile): void => {
        splitbee.user.set({email: user.email})
    }
    logout = (): void => {
        splitbee.reset()
    }
}

export class LogAnalytics implements Analytics {
    constructor(private logger: Logger) {
    }

    trackPage = (name: string): void => this.logger.debug('analytics.page', name)
    trackEvent = (name: string, details?: Data): void => this.logger.debug('analytics.event', name, details)
    trackError = (name: string, details?: Data): void => this.logger.debug('analytics.error', name, details)
    login = (user: Profile): void => this.logger.debug('analytics.login', user)
    logout = (): void => this.logger.debug('analytics.logout')
}
