import {ElmInit, ElmRuntime} from "./elm";
import {AzimuttApi} from "../services/api";

declare global {
    export interface Window {
        Elm: { Main: { init: (f: ElmInit) => ElmRuntime } }
        azimutt: AzimuttApi
        supabase: Supabase
        splitbee: Splitbee
        Sentry: Sentry
        uuidv4: () => string
    }
}

export interface Supabase {
    createClient: (url: string, publicKey: string) => SupabaseClient
}

export interface SupabaseClient {
    auth: {
        signIn: (conf: any, opts: any) => Promise<any>,
        signOut: () => Promise<any>
        getSessionFromUrl: (a: any) => Promise<any>
        user: () => SupabaseUser | null
    }
}

export type SupabaseUser = any

export interface Splitbee {
    track: (name: string, details: object) => void
}

export interface Sentry {
    captureException: (e: Error) => void
}
