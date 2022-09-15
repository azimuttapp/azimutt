import {ElmFlags, ElmMsg, ElmProgram, JsMsg} from "./elm";
import {AzimuttApi} from "../services/api";

declare global {
    export interface Window {
        Elm: { Main: ElmProgram<ElmFlags, JsMsg, ElmMsg> }
        azimutt: AzimuttApi
    }
}
