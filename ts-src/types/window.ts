import {ElmInit, ElmRuntime} from "./elm";
import {AzimuttApi} from "../services/api";
import {SupabaseClient} from "@supabase/supabase-js";
import {SupabaseClientOptions} from "@supabase/supabase-js/src/lib/types";

declare global {
    export interface Window {
        Elm: { Main: { init: (f: ElmInit) => ElmRuntime } }
        azimutt: AzimuttApi
        supabase: { createClient: (supabaseUrl: string, supabaseKey: string, options?: SupabaseClientOptions) => SupabaseClient }
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
