import {ElmInit, ElmRuntime} from "./elm";
import {AzimuttApi} from "../services/api";

declare global {
    export interface Window {
        Elm: { Main: { init: (f: ElmInit) => ElmRuntime } }
        azimutt: AzimuttApi
        splitbee: Splitbee
        Sentry: Sentry
        uuidv4: () => string
    }
}

export interface Splitbee {
    track: (name: string, details: object) => void
}

export interface Sentry {
    captureException: (e: Error) => void
}
