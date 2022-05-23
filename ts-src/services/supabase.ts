import {AuthChangeEvent, createClient, Session, SupabaseClient} from "@supabase/supabase-js";
import {User as SupabaseUser, UserCredentials} from "@supabase/gotrue-js/src/lib/types";
import {Profile, UserId} from "../types/profile";
import {SupabaseClientOptions} from "@supabase/supabase-js/src/lib/types";
import {Project, ProjectId, ProjectInfo} from "../types/project";
import {StorageApi, StorageKind} from "../storages/api";
import {Email, Env} from "../types/basics";
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
        return new Supabase(createClient(supabaseUrl, supabaseKey, options))
    }

    private user: SupabaseUser | null = null
    private store: SupabaseStorage
    private events: Partial<{ [key in AuthChangeEvent]: (Session | null)[] }> = {}
    private callbacks: Partial<{ [key in AuthChangeEvent]: ((session: Session | null) => void)[] }> = {}

    constructor(private supabase: SupabaseClient) {
        this.store = new SupabaseStorage(supabase)
        supabase.auth.onAuthStateChange((event, session) => {
            const callbacks = this.callbacks[event]
            if (callbacks === undefined) {
                const events = this.events[event]
                if (events === undefined) {
                    this.events[event] = [session]
                } else {
                    events.push(session)
                }
            } else {
                callbacks.forEach(cb => cb(session))
            }

            if (event === 'SIGNED_IN' || event === 'USER_UPDATED') {
                this.user = session !== null ? session.user : null
            } else if (event === 'SIGNED_OUT') {
                this.user = null
            }
        })
    }

    login = (credentials: LoginInfo, redirect?: string): Promise<Profile> => {
        return this.supabase.auth.signIn(
            formatLogin(credentials),
            redirect ? {redirectTo: `${window.location.origin}${redirect}`} : {}
        ).then(res => {
            if (res.error) {
                return Promise.reject(`Can't login: ${res.error}`)
            } else if (res.user !== null) {
                return this.store.getOrCreateProfile(res.user)
            } else {
                return Promise.reject('No user')
            }
        })
    }

    logout = (): Promise<void> => {
        return this.supabase.auth.signOut().then(res => {
            if (res.error) return Promise.reject(`Can't logout: ${JSON.stringify(res.error)}`)
        })
    }

    onLogin(callback: (p: Profile) => void): Supabase {
        return this.on('SIGNED_IN', session => {
            if (session !== null && session.user !== null) {
                this.store.getOrCreateProfile(session.user).then(callback)
            }
        })
    }

    on(event: AuthChangeEvent, callback: (session: Session | null) => void): Supabase {
        const callbacks = this.callbacks[event]
        if (callbacks === undefined) {
            this.callbacks[event] = [callback]
        } else {
            callbacks.push(callback)
        }

        const events = this.events[event]
        if (events !== undefined) {
            events.forEach(callback)
            delete this.events[event]
        }

        return this
    }

    // deleteAccount = (): Promise<void> => this.supabase.auth.update({data: {deleted_at: Date.now()}})

    kind: StorageKind = 'supabase'
    listProjects = (): Promise<ProjectInfo[]> => this.waitLogin(500, _ => this.store.getProjects(), () => Promise.resolve([]))
    loadProject = (id: ProjectId): Promise<Project> => this.waitLogin(500, _ => this.store.getProject(id))
    createProject = (p: Project): Promise<Project> => this.waitLogin(500, u => this.store.createProject(p, u.id))
    updateProject = (p: Project): Promise<Project> => this.waitLogin(500, _ => this.store.updateProject(p))
    dropProject = (p: ProjectInfo): Promise<void> => this.waitLogin(500, _ => this.store.dropProject(p))

    getUser = (email: Email): Promise<Profile | undefined> => this.store.fetchProfile(email)
    getOwners = (id: ProjectId): Promise<Profile[]> => this.store.getOwners(id)
    setOwners = (id: ProjectId, owners: UserId[]): Promise<Profile[]> => this.store.setOwners(id, owners)

    private waitLogin<T>(timeout: number, success: (u: SupabaseUser) => Promise<T>, failure: () => Promise<T> = () => Promise.reject('try to log in')): Promise<T> {
        if (this.user !== null) {
            return success(this.user)
        } else if (timeout > 0) {
            return new Promise<T>((resolve, reject) => {
                setTimeout(() => {
                    this.waitLogin(timeout - 100, success, failure).then(resolve, reject)
                }, 100)
            })
        } else {
            return failure()
        }
    }
}

export interface SupabaseConf {
    supabaseUrl: string
    supabaseKey: string
    options?: SupabaseClientOptions
}

export type LoginInfo = { kind: 'Github' } | { kind: 'MagicLink', email: Email }

// HELPERS

function formatLogin(creds: LoginInfo): UserCredentials {
    if (creds.kind === 'Github') {
        return {provider: 'github'}
    } else if (creds.kind === 'MagicLink') {
        return {email: creds.email}
    } else {
        throw new Error(`Unknown creds: ${creds}`)
    }
}
