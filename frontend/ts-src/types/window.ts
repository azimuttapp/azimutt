import {DesktopBridge} from "@azimutt/shared";
import {ElmFlags, ElmMsg, ElmProgram, JsMsg} from "./ports";
import {AzimuttApi} from "../services/api";
import {Env} from "../utils/env";

declare global {
    export interface Window {
        Elm: { Main: ElmProgram<ElmFlags, JsMsg, ElmMsg> }
        azimutt: AzimuttApi
        isDirty: boolean
        env: Env
        base_path: string
        gateway_url: string
        sentry_frontend_dsn?: string
        desktop?: DesktopBridge
    }
}
