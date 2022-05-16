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

    user: User | null = null

    constructor(private supabase: SupabaseClient) {
    }

    getLoggedUser = (): User | null => {
        const user = this.supabase.auth.user()
        this.user = user !== null ? supabaseToAzimuttUser(user) : null
        return this.user
    }

    init = (app: ElmApp, logger: Logger): Supabase => {
        return new Supabase(this.supabase, this.user, app, logger)
    }
}

export class Supabase implements StorageApi {
    projectsBucket = 'projects'

    constructor(private supabase: SupabaseClient, private user: User | null, private app: ElmApp, private logger: Logger) {
    }

    login = (redirect?: string): Promise<void> => {
        return this.supabase.auth.signIn(
            {provider: 'github'},
            redirect ? {redirectTo: `${window.location.origin}${redirect}`} : {}
        ).then(res => {
            if (res.error) {
                this.logger.warn(`Can't login`, res.error)
            } else if (res.user) {
                this.user = supabaseToAzimuttUser(res.user)
                this.app.login(this.user)
            } else {
                this.logger.warn(`No user`)
            }
        })
    }

    logout = (): Promise<void> => {
        return this.supabase.auth.signOut().then(res => {
            if (res.error) {
                this.logger.warn(`Can't logout`, res.error)
            } else {
                this.user = null
                return this.app.logout()
            }
        })
    }

    onLogin(callback: (u: User) => void) {
        // login on redirect, session is in url but not yet stored, so get it from there
        this.supabase.auth.getSessionFromUrl({storeSession: true}).then(res => {
            const user = res?.data?.user
            if (user) {
                this.user = supabaseToAzimuttUser(user)
                callback(this.user)
            }
        })
    }

    // storage

    kind: StorageKind = 'supabase'
    loadProjects = async (): Promise<Project[]> => {
        if (!this.user) {
            return []
        }
        const files = await this.getBucket().list().then(resultToPromise)
        return await Promise.all(files.map(file =>
            this.getBucket().download(file.name)
                .then(resultToPromise)
                .then(blob => blob.text())
                .then(json => JSON.parse(json) as Project)
        ))
    }
    saveProject = async (p: Project): Promise<void> => {
        if (!this.user) {
            return Promise.reject('Not logged in')
        }
        return await this.getBucket().upload(this.projectPath(p), JSON.stringify(p), {
            contentType: 'application/json;charset=UTF-8',
            upsert: true
        }).then(resultToPromise).then(_ => undefined)
    }
    dropProject = async (p: Project): Promise<void> => {
        if (!this.user) {
            return Promise.reject('Not logged in')
        }
        return await this.getBucket().remove([this.projectPath(p)]).then(resultToPromise).then(_ => undefined)
    }
    private getBucket = () => this.supabase.storage.from(this.projectsBucket)
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
