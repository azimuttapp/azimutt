import {AuthChangeEvent, createClient, Session, SupabaseClient} from "@supabase/supabase-js";
import {User as SupabaseUser, UserCredentials} from "@supabase/gotrue-js/src/lib/types";
import {Profile, UserId} from "../types/profile";
import {ProjectId, ProjectInfoNoStorage, ProjectNoStorage} from "../types/project";
import {StorageApi, StorageKind} from "../storages/api";
import {Email} from "../types/basics";
import {SupabaseStorage} from "../storages/supabase";
import {SupabaseConf} from "../conf";

export class Supabase implements StorageApi {
    static init({backendUrl, supabaseUrl, supabaseKey, options}: SupabaseConf): Supabase {
        return new Supabase(createClient(supabaseUrl, supabaseKey, options), backendUrl)
    }

    private user: SupabaseUser | null = null
    private store: SupabaseStorage
    private events: Partial<{ [key in AuthChangeEvent]: (Session | null)[] }> = {}
    private callbacks: Partial<{ [key in AuthChangeEvent]: ((session: Session | null) => void)[] }> = {}

    constructor(private supabase: SupabaseClient, backendUrl: string) {
        this.store = new SupabaseStorage(supabase, backendUrl)
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

    onLogin(callback: (p: Profile) => void, errorCallback: (err: string) => void): Supabase {
        return this.on('SIGNED_IN', session => {
            if (session !== null && session.user !== null && this.user === null) {
                this.store.getOrCreateProfile(session.user).then(callback).catch(errorCallback)
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

    // FIXME deleteAccount = (): Promise<void> => this.supabase.auth.update({data: {deleted_at: Date.now()}})

    kind: StorageKind = 'supabase'
    listProjects = (): Promise<ProjectInfoNoStorage[]> => this.waitLogin(500, _ => this.store.getProjects(), () => Promise.resolve([]))
    loadProject = (id: ProjectId): Promise<ProjectNoStorage> => this.waitLogin(500, _ => this.store.getProject(id))
    createProject = (p: ProjectNoStorage): Promise<ProjectNoStorage> => this.waitLogin(500, _ => this.store.createProject(p))
    updateProject = (p: ProjectNoStorage): Promise<ProjectNoStorage> => this.waitLogin(500, _ => this.store.updateProject(p))
    dropProject = (id: ProjectId): Promise<void> => this.waitLogin(500, _ => this.store.dropProject(id))

    getUser = (email: Email): Promise<Profile> => this.store.fetchProfile(email)
    updateUser = (user: Profile): Promise<void> => this.store.updateProfile(user)
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
