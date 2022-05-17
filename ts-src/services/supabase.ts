import {SupabaseClient} from "@supabase/supabase-js";
import {User as SupabaseUser} from "@supabase/gotrue-js/src/lib/types";
import {User} from "../types/user";
import {SupabaseClientOptions} from "@supabase/supabase-js/src/lib/types";
import {Project} from "../types/project";
import {StorageApi, StorageKind} from "../storages/api";

/*
Tables (https://dbdiagram.io/d/628351d27f945876b6310c15):
    - projects (id, name, tables, layouts, created_at, updated_at)
    - project_accesses (project_id, user_id, access (owner, write, read, none), created_at, created_by)
Storage:
    - policies (storage.objects)
 */

export interface SupabaseConf {
    supabaseUrl: string
    supabaseKey: string
    options?: SupabaseClientOptions
    projectsBucket: string
}

export class Supabase implements StorageApi {
    static init({supabaseUrl, supabaseKey, options, projectsBucket}: SupabaseConf): Supabase {
        return new Supabase(window.supabase.createClient(supabaseUrl, supabaseKey, options), projectsBucket)
    }

    constructor(private supabase: SupabaseClient, private projectsBucket: string, private user: User | null = null) {
    }

    getLoggedUser = (): User | null => {
        const user = this.supabase.auth.user()
        this.user = user !== null ? supabaseToAzimuttUser(user) : null
        return this.user
    }

    login = (redirect?: string): Promise<User> => {
        return this.supabase.auth.signIn(
            {provider: 'github'},
            redirect ? {redirectTo: `${window.location.origin}${redirect}`} : {}
        ).then(res => {
            if (res.error) {
                return Promise.reject(`Can't login: ${res.error}`)
            } else if (res.user) {
                return this.user = supabaseToAzimuttUser(res.user)
            } else {
                return Promise.reject('No user')
            }
        })
    }

    logout = (): Promise<void> => {
        return this.supabase.auth.signOut().then(res => {
            if (res.error) {
                return Promise.reject(`Can't logout: ${res.error}`)
            } else {
                this.user = null
            }
        })
    }

    onLogin(callback: (u: User) => void): Supabase {
        // login on redirect, session is in url but not yet stored, so get it from there
        this.supabase.auth.getSessionFromUrl({storeSession: true}).then(res => {
            const user = res?.data?.user
            if (user) {
                this.user = supabaseToAzimuttUser(user)
                callback(this.user)
            }
        })
        return this
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
