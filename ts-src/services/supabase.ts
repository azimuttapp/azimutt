import {SupabaseClient} from "@supabase/supabase-js";
import {ElmApp} from "./elm";
import {User as SupabaseUser} from "@supabase/gotrue-js/src/lib/types";
import {User} from "../types/user";
import {SupabaseClientOptions} from "@supabase/supabase-js/src/lib/types";

interface SupabaseConf {
    supabaseUrl: string
    supabaseKey: string
    options?: SupabaseClientOptions
}

export class SupabaseInitializer {
    static init(conf: SupabaseConf): SupabaseInitializer {
        return new SupabaseInitializer(window.supabase.createClient(conf.supabaseUrl, conf.supabaseKey, conf.options))
    }

    constructor(private supabase: SupabaseClient) {
    }

    getLoggedUser = (): User | null => {
        const user = this.supabase.auth.user()
        return user !== null ? supabaseToAzimuttUser(user) : null
    }

    init = (app: ElmApp): Supabase => {
        return new Supabase(this.supabase, app)
    }
}

export class Supabase {
    constructor(private supabase: SupabaseClient, private app: ElmApp) {
        // on redirect, session is in url but not yet stored, so get it from there
        this.supabase.auth.getSessionFromUrl({storeSession: true}).then(res => {
            const user = res?.data?.user
            if (user) {
                app.login(supabaseToAzimuttUser(user))
            }
        })
    }

    login = (redirect?: string): Promise<void> => {
        return this.supabase.auth.signIn(
            {provider: 'github'},
            redirect ? {redirectTo: `${window.location.origin}${redirect}`} : {}
        ).then(res => {
            if (res.error) {
                console.warn(`Can't login`, res.error)
            } else {
                const user = res.user
                user !== null ? this.app.login(supabaseToAzimuttUser(user)) : console.warn(`No user`)
            }
        })
    }

    logout = (): Promise<void> => {
        return this.supabase.auth.signOut()
            .then(res => res.error ? console.warn(`Can't logout`, res.error) : this.app.logout())
    }
}

function supabaseToAzimuttUser(user: SupabaseUser): User {
    return {
        id: user.id, // uuid
        username: user.user_metadata.user_name,
        name: user.user_metadata.name,
        email: user.email,
        avatar: user.user_metadata.avatar_url,
        role: user.role, // ex: authenticated
        provider: user.app_metadata.provider // ex: github
    }
}
