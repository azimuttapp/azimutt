import {SupabaseClient} from "@supabase/supabase-js";
import {ElmApp} from "./elm";
import {User as SupabaseUser} from "@supabase/gotrue-js/src/lib/types";
import {User} from "../types/user";
import {SupabaseClientOptions} from "@supabase/supabase-js/src/lib/types";
import {Project} from "../types/project";
import {StorageApi, StorageKind} from "../storages/api";
import {Logger} from "./logger";

export interface SupabaseConf {
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

    init = (app: ElmApp, logger: Logger): Supabase => {
        return new Supabase(this.supabase, app, logger)
    }
}

export class Supabase implements StorageApi {
    constructor(private supabase: SupabaseClient, private app: ElmApp, private logger: Logger) {
        // login on redirect, session is in url but not yet stored, so get it from there
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
                this.logger.warn(`Can't login`, res.error)
            } else {
                const user = res.user
                user !== null ? this.app.login(supabaseToAzimuttUser(user)) : this.logger.warn(`No user`)
            }
        })
    }

    logout = (): Promise<void> => {
        return this.supabase.auth.signOut()
            .then(res => res.error ? this.logger.warn(`Can't logout`, res.error) : this.app.logout())
    }

    // storage

    // TODO add cache
    kind: StorageKind = 'supabase'
    loadProjects = async (): Promise<Project[]> => {
        const files = await this.getStore().list().then(resultToPromise)
        return await Promise.all(files.map(file =>
            this.getStore().download(file.name)
                .then(resultToPromise)
                .then(blob => blob.text())
                .then(json => JSON.parse(json) as Project)
        ))
    }
    saveProject = async (p: Project): Promise<void> => {
        return await this.getStore().upload(this.projectPath(p), JSON.stringify(p), {
            contentType: 'application/json;charset=UTF-8',
            upsert: true
        }).then(resultToPromise).then(_ => undefined)
    }
    dropProject = async (p: Project): Promise<void> => {
        return await this.getStore().remove([this.projectPath(p)]).then(resultToPromise).then(_ => undefined)
    }
    private getStore = () => this.supabase.storage.from('projects')
    private projectPath = (p: Project) => `${p.id}.json`
}

type Result<T> = { data: T | null; error: Error | null }

function resultToPromise<T>(res: Result<T>): Promise<T> {
    return res.error ? Promise.reject(res.error) :
        res.data === null ? Promise.reject('Data is null') :
            Promise.resolve(res.data)
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
