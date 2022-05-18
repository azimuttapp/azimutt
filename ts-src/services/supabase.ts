import {SupabaseClient} from "@supabase/supabase-js";
import {User as SupabaseUser, UserCredentials} from "@supabase/gotrue-js/src/lib/types";
import {User} from "../types/user";
import {SupabaseClientOptions} from "@supabase/supabase-js/src/lib/types";
import {Project, ProjectId, ProjectInfo, ProjectStorage} from "../types/project";
import {computeRelations, computeTables, projectToInfo, StorageApi, StorageKind} from "../storages/api";
import {Email, Env} from "../types/basics";
import {PostgrestError} from "@supabase/postgrest-js/src/lib/types";

/*
# Tables (https://dbdiagram.io/d/628351d27f945876b6310c15)

auth.users
  id uuid
  role varchar
  email varchar
  created_at timestamptz
  updated_at timestamptz

projects | list of stored projects
  id uuid pk
  name varchar
  tables int2
  relations int2
  layouts int2
  project json
  created_at timestamptz default=now()
  created_by uuid default=auth.uid() fk auth.users.id
  updated_at timestamptz default=now()
  updated_by uuid default=auth.uid() fk auth.users.id

project_accesses | give access to stored projects
  id uuid default=uuid_generate_v4() pk
  user_id uuid fk auth.users.id
  project_id uuid fk projects.id
  access varchar | values: owner, write, read, none
  created_at timestamptz default=now()
  created_by uuid default=auth.uid() fk auth.users.id
  updated_at timestamptz default=now()
  updated_by uuid default=auth.uid() fk auth.users.id

# Policies (examples: https://github.com/steve-chavez/socnet/blob/master/security/users.sql)

CREATE POLICY "See your rights" ON "public"."project_accesses"
AS PERMISSIVE FOR SELECT
TO authenticated
USING (auth.uid() = user_id)

CREATE POLICY "Create new rights" ON "public"."project_accesses"
AS PERMISSIVE FOR INSERT
TO authenticated
WITH CHECK ((auth.uid() in (select user_id from project_accesses pa where project_id=pa.project_id and access='owner')))
 */

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

    store: StorageApi

    constructor(private supabase: SupabaseClient, private user: User | null = null) {
        // this.store = new FileStorage(supabase, 'projects')
        this.store = new DbStorage(supabase)
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

    kind: StorageKind = 'supabase'
    listProjects = (): Promise<ProjectInfo[]> => this.user ? this.store.listProjects() : Promise.resolve([])
    loadProject = (id: ProjectId): Promise<Project> => this.user ? this.store.loadProject(id) : Promise.reject('Not logged in')
    createProject = (p: Project): Promise<void> => this.user ? this.store.createProject(p) : Promise.reject('Not logged in')
    updateProject = (p: Project): Promise<void> => this.user ? this.store.updateProject(p) : Promise.reject('Not logged in')
    dropProject = (p: ProjectInfo): Promise<void> => this.user ? this.store.dropProject(p) : Promise.reject('Not logged in')
}

export interface SupabaseConf {
    supabaseUrl: string
    supabaseKey: string
    options?: SupabaseClientOptions
}

export type LoginInfo = { kind: 'Github' } | { kind: 'MagicLink', email: Email }

class DbStorage implements StorageApi {
    constructor(private supabase: SupabaseClient) {
    }

    kind: StorageKind = 'supabase'
    listProjects = async (): Promise<ProjectInfo[]> => {
        const projects = await this.supabase.from('projects')
            .select('id, name, tables, relations, layouts, created_at, updated_at').then(resultToPromise)
        return projects.map(p => ({
            id: p.id,
            name: p.name,
            tables: p.tables,
            relations: p.relations,
            layouts: p.layouts,
            storage: ProjectStorage.cloud,
            createdAt: new Date(p.created_at).getTime(),
            updatedAt: new Date(p.updated_at).getTime()
        }))
    }
    loadProject = async (id: ProjectId): Promise<Project> => {
        const projects = await this.supabase.from('projects')
            .select('project').match({id}).then(resultToPromise)
        return projects.length === 1 ? projects[0].project : Promise.reject(`Project ${id} not found`)
    }
    createProject = async (p: Project): Promise<void> => {
        if (isSample(p)) {
            return Promise.reject("Sample projects can't be uploaded!")
        }
        return await this.supabase.from('projects').insert({
            id: p.id,
            name: p.name,
            tables: computeTables(p.sources),
            relations: computeRelations(p.sources),
            layouts: Object.keys(p.layouts).length,
            project: p,
        }, {returning: 'minimal'}).then(checkResult)
    }
    updateProject = async (p: Project): Promise<void> => {
        return await this.supabase.from('projects').update({
            name: p.name,
            tables: computeTables(p.sources),
            relations: computeRelations(p.sources),
            layouts: Object.keys(p.layouts).length,
            project: p,
            // FIXME update updated_at & updated_by: https://github.com/supabase/supabase/issues/379#issuecomment-1005614974
            // FIXME prevent edit other fields: https://dev.to/jdgamble555/supabase-date-protection-on-postgresql-1n91
        }).match({id: p.id}).then(checkResult)
    }
    dropProject = async (p: ProjectInfo): Promise<void> => {
        return await this.supabase.from('projects').delete()
            .match({id: p.id}).then(checkDelete)
    }
}

// slow query as needs to load everything and files are not saved in backup, use db instead!
class FileStorage implements StorageApi {
    constructor(private supabase: SupabaseClient, private projectsBucket: string) {
    }

    kind: StorageKind = 'supabase'
    listProjects = async (): Promise<ProjectInfo[]> => {
        const files = await this.getBucket().list().then(resultToPromise)
        const projects = await Promise.all(files.map(file => this.download(file.name)))
        return projects.map(projectToInfo)
    }
    loadProject = (id: ProjectId): Promise<Project> => this.download(this.projectPath(id))
    createProject = async (p: Project): Promise<void> => {
        if (isSample(p)) {
            return Promise.reject("Sample projects can't be uploaded!")
        }
        return await this.getBucket().upload(this.projectPath(p.id), JSON.stringify(p), {
            contentType: 'application/json;charset=UTF-8',
            upsert: true
        }).then(resultToPromise).then(_ => undefined)
    }
    updateProject = async (p: Project): Promise<void> => this.createProject(p)
    dropProject = (p: ProjectInfo): Promise<void> => this.getBucket().remove([this.projectPath(p.id)]).then(resultToPromise).then(_ => undefined)
    private getBucket = () => this.supabase.storage.from(this.projectsBucket)
    private projectPath = (id: ProjectId) => `${id}.json`
    private download = async (path: string): Promise<Project> => {
        return await this.getBucket().download(path)
            .then(resultToPromise)
            .then(blob => blob.text())
            .then(json => JSON.parse(json) as Project)
    }
}

// HELPERS

type Result<T> = { data: T | null; error: Error | PostgrestError | null }

function resultToPromise<T>(res: Result<T>): Promise<T> {
    return res.error ? Promise.reject(res.error.message ? res.error.message : res.error) :
        res.data === null ? Promise.reject('Data is null') :
            Promise.resolve(res.data)
}

function checkResult<T>(res: Result<T>): Promise<void> {
    return res.error === null ? Promise.resolve(undefined) : Promise.reject(res.error.message ? res.error.message : res.error)
}

function checkDelete<T>(res: Result<T[]>): Promise<void> {
    return res.error === null && res.data?.length === 1 ? Promise.resolve(undefined) : Promise.reject(`Can't delete: ${res.error?.message}`)
}

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

function isSample(p: Project): boolean {
    return p.id.startsWith('0000')
}
