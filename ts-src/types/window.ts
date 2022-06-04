import {ElmInit, ElmRuntime} from "./elm";
import {AzimuttApi} from "../services/api";

declare global {
    export interface Window {
        Elm: { Main: { init: (f: ElmInit) => ElmRuntime } }
        azimutt: AzimuttApi
    }
}
