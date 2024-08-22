import {DesktopBridge} from "@azimutt/models";
import {ElmFlags, ElmMsg, ElmProgram, JsMsg} from "./ports";
import {UserRole} from "./basics";
import {AzimuttApi} from "../services/api";
import {Env} from "../utils/env";

declare global {
    export interface Window {
        Elm: { Main: ElmProgram<ElmFlags, JsMsg, ElmMsg> }
        azimutt: AzimuttApi
        isDirty: boolean
        env: Env
        role: UserRole
        gateway_url: string
        sentry_frontend_dsn?: string
        desktop?: DesktopBridge
    }
}
