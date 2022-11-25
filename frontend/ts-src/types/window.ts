import {ElmFlags, ElmMsg, ElmProgram, JsMsg} from "./ports";
import {AzimuttApi} from "../services/api";
import {Plausible} from "../services/analytics";

declare global {
    export interface Window {
        Elm: { Main: ElmProgram<ElmFlags, JsMsg, ElmMsg> }
        azimutt: AzimuttApi
        plausible?: Plausible
        isDirty: boolean
    }
}
