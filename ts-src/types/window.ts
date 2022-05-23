import {ElmInit, ElmRuntime} from "./elm";
import {AzimuttApi} from "../services/api";
import {SupabaseClient} from "@supabase/supabase-js";
import {SupabaseClientOptions} from "@supabase/supabase-js/src/lib/types";

declare global {
    export interface Window {
        Elm: { Main: { init: (f: ElmInit) => ElmRuntime } }
        azimutt: AzimuttApi
        uuidv4: () => string
    }
}
