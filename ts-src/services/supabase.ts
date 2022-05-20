import {SupabaseClient} from "@supabase/supabase-js";
import {User as SupabaseUser, UserCredentials} from "@supabase/gotrue-js/src/lib/types";
import {User} from "../types/user";
import {SupabaseClientOptions} from "@supabase/supabase-js/src/lib/types";
import {Project, ProjectId, ProjectInfo} from "../types/project";
import {StorageApi, StorageKind} from "../storages/api";
import {Email, Env, Username} from "../types/basics";
import {SupabaseStorage} from "../storages/supabase";

export class Supabase implements StorageApi {
    // https://supabase.com/docs/guides/local-development
    static conf: { [env in Env]: SupabaseConf } = {
        dev: {
            supabaseUrl: 'http://localhost:54321',
            // dbUrl: 'postgresql://postgres:postgres@localhost:54322/postgres',
            // studioUrl: 'http://localhost:54323',
            // inbucketUrl: 'http://localhost:54324',
            supabaseKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZS1kZW1vIiwicm9sZSI6ImFub24ifQ.625_WdcF3KHqz5amU0x2X5WWHP-OEs_4qj0ssLNHzTs',
            // serviceRoleKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZS1kZW1vIiwicm9sZSI6InNlcnZpY2Vfcm9sZSJ9.vI9obAHOGyVVKa3pD--kJlyxp-Z2zV9UUMAhKpNLAcU',
        },
        staging: {
            supabaseUrl: 'https://ywieybitcnbtklzsfxgd.supabase.co',
            supabaseKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Inl3aWV5Yml0Y25idGtsenNmeGdkIiwicm9sZSI6ImFub24iLCJpYXQiOjE2NTE5MjI3MzUsImV4cCI6MTk2NzQ5ODczNX0.ccfB_pVemOqeR4CwhSoGmwfT5bx-FAuY24IbGj7OjiE',
        },
        prod: {
            supabaseUrl: '',
            supabaseKey: '',
        }
    }

    static init(env: Env): Supabase {
        const {supabaseUrl, supabaseKey, options} = this.conf['staging'] // social auth & file storage not supported in local :(
        return new Supabase(window.supabase.createClient(supabaseUrl, supabaseKey, options))
    }

    store: SupabaseStorage

    constructor(private supabase: SupabaseClient, private user: User | null = null) {
        this.store = new SupabaseStorage(supabase)
    }

    getLoggedUser = (): User | null => {
        const user = this.supabase.auth.user()
        this.user = user !== null ? supabaseToAzimuttUser(user) : null
        return this.user
    }

    login = (credentials: LoginInfo, redirect?: string): Promise<User> => {
        return this.supabase.auth.signIn(
            formatLogin(credentials),
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
                return Promise.reject(`Can't logout: ${JSON.stringify(res.error)}`)
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

    // deleteAccount = (): Promise<void> => this.supabase.auth.update({data: {deleted_at: Date.now()}})

    kind: StorageKind = 'supabase'
    listProjects = (): Promise<ProjectInfo[]> => this.user ? this.store.listProjects() : Promise.resolve([])
    loadProject = (id: ProjectId): Promise<Project> => this.user ? this.store.loadProject(id) : Promise.reject('Not logged in')
    createProject = (p: Project): Promise<Project> => this.user ? this.store.createProject(p, this.user) : Promise.reject('Not logged in')
    updateProject = (p: Project): Promise<Project> => this.user ? this.store.updateProject(p) : Promise.reject('Not logged in')
    dropProject = (p: ProjectInfo): Promise<void> => this.user ? this.store.dropProject(p) : Promise.reject('Not logged in')

    findUser = (email: Email | Username): Promise<User[]> => {
        // https://supabase.com/docs/guides/auth/managing-user-data
        return Promise.reject('Not found')
    }
    // shareProject = (p: Project, user: UserInfo, access: UserAccess): Promise<void> => { throw 'TODO' },
}

export interface SupabaseConf {
    supabaseUrl: string
    supabaseKey: string
    options?: SupabaseClientOptions
}

export type LoginInfo = { kind: 'Github' } | { kind: 'MagicLink', email: Email }

// HELPERS

function supabaseToAzimuttUser(user: SupabaseUser): User {
    return {
        id: user.id, // uuid
        username: user.user_metadata.user_name || user.email?.split('@')[0],
        name: user.user_metadata.name || user.email?.split('@')[0],
        email: user.email,
        avatar: user.user_metadata.avatar_url || '/assets/images/guest.png',
        role: user.role, // ex: authenticated
        provider: user.app_metadata.provider // ex: github or email
    }
}

function formatLogin(creds: LoginInfo): UserCredentials {
    if (creds.kind === 'Github') {
        return {provider: 'github'}
    } else if (creds.kind === 'MagicLink') {
        return {email: creds.email}
    } else {
        throw new Error(`Unknown creds: ${creds}`)
    }
}
