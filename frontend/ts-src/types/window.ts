import {ElmFlags, ElmMsg, ElmProgram, JsMsg} from "./ports";
import {AzimuttApi} from "../services/api";

declare global {
    export interface Window {
        Elm: { Main: ElmProgram<ElmFlags, JsMsg, ElmMsg> }
        azimutt: AzimuttApi
        isDirty: boolean
        host: string
        sentry_frontend_dsn?: string
    }
}
