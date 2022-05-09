import {AzimuttApi} from "./api";
import {ElmInit, ElmRuntime} from "./elm";
import {Splitbee} from "./splitbee";
import {Sentry} from "./sentry";

declare global {
    export interface Window {
        Elm: { Main: { init: (f: ElmInit) => ElmRuntime } }
        azimutt: AzimuttApi
        splitbee: Splitbee
        Sentry: Sentry
        uuidv4: () => string
    }
}
