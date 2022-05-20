import {computeRelations, computeTables} from "./api";
import {SupabaseClient} from "@supabase/supabase-js";
import {Project, ProjectId, ProjectInfo, ProjectStorage} from "../types/project";
import {PostgrestError} from "@supabase/postgrest-js/src/lib/types";
import {Profile, UserId} from "../types/profile";
import {User as SupabaseUser} from "@supabase/gotrue-js/src/lib/types";
import {Email, Username} from "../types/basics";

const db = {
    profiles: {
        table: 'profiles',
        columns: 'id, email, username, name, avatar, bio, company, location, website, github, twitter',
    },
    projects: {
        table: 'projects',
        infoColumns: 'id, name, tables, relations, layouts, created_at, updated_at'
    }
}

export class SupabaseStorage {
    constructor(private supabase: SupabaseClient) {
    }

    getProfile = async (id: UserId): Promise<Profile | undefined> => {
        return await this.supabase.from(db.profiles.table).select(db.profiles.columns)
            .match({id}).maybeSingle().then(optResult)
    }
    fetchProfile = async (input: Email | Username): Promise<Profile | undefined> => {
        return await this.supabase.from(db.profiles.table).select(db.profiles.columns)
            .or(`email.eq.${input},username.eq.${input}`).maybeSingle().then(optResult)
    }
    createProfile = async (user: SupabaseUser): Promise<Profile> => {
        if (!user.email) return Promise.reject('missing email')
        const profile: Profile = {
            id: user.id,
            email: user.email,
            username: user.user_metadata.user_name || user.email.split('@')[0],
            name: user.user_metadata.name || user.email.split('@')[0],
            avatar: user.user_metadata.avatar_url,
            bio: null,
            company: null,
            location: null,
            website: null,
            github: null,
            twitter: null
        }
        return await this.supabase.from<Profile>(db.profiles.table).insert(profile).then(insertResult)
    }
    getOrCreateProfile = async (user: SupabaseUser): Promise<Profile> => this.getProfile(user.id).then(p => p ? p : this.createProfile(user))


    listProjects = async (): Promise<ProjectInfo[]> => {
        return await this.supabase.from(db.projects.table).select(db.projects.infoColumns)
            .then(listResult).then(projects => projects.map(p => ({
                id: p.id,
                name: p.name,
                tables: p.tables,
                relations: p.relations,
                layouts: p.layouts,
                storage: ProjectStorage.cloud,
                createdAt: new Date(p.created_at).getTime(),
                updatedAt: new Date(p.updated_at).getTime()
            })))
    }
    loadProject = async (id: ProjectId): Promise<Project> => {
        return await this.supabase.from(db.projects.table).select('project')
            .match({id}).maybeSingle().then(singleResult).then(p => p.project)
    }
    createProject = async (p: Project, user: UserId): Promise<Project> => {
        if (isSample(p)) return Promise.reject("Sample projects can't be uploaded!")
        const now = Date.now()
        const prj = {...p, createdAt: now, updatedAt: now}
        return await this.supabase.from(db.projects.table).insert({
            id: p.id,
            name: p.name,
            tables: computeTables(p.sources),
            relations: computeRelations(p.sources),
            layouts: Object.keys(p.layouts).length,
            project: prj,
            owners: [user]
        }).then(insertResult).then(p => p.project)
    }
    updateProject = async (p: Project): Promise<Project> => {
        const prj = {...p, updatedAt: Date.now()}
        return await this.supabase.from(db.projects.table).update({
            name: p.name,
            tables: computeTables(p.sources),
            relations: computeRelations(p.sources),
            layouts: Object.keys(p.layouts).length,
            project: prj
        }).match({id: p.id}).then(updateResult).then(p => p.project)
    }
    // shareProject = (p: Project, user: UserInfo, access: UserAccess): Promise<void> => { throw 'TODO' },
    dropProject = async (p: ProjectInfo): Promise<void> => {
        return await this.supabase.from(db.projects.table).delete()
            .match({id: p.id}).then(deleteResult)
    }
}

type Result<T> = { data: T | null; error: Error | PostgrestError | null }

function listResult<T>(res: Result<T>): Promise<T> {
    return res.error !== null ? Promise.reject(res.error.message ? res.error.message : res.error) :
        res.data !== null ? Promise.resolve(res.data) : Promise.reject('null data in supabase response')
}

function singleResult<T>(res: Result<T>): Promise<T> {
    return res.error !== null ? Promise.reject(res.error.message ? res.error.message : res.error) :
        res.data !== null ? Promise.resolve(res.data) : Promise.reject(`not found`)
}

function optResult<T>(res: Result<T>): Promise<T | null> {
    return res.error !== null ? Promise.reject(res.error.message ? res.error.message : res.error) : Promise.resolve(res.data)
}

function insertResult<T>(res: Result<T[]>): Promise<T> {
    return res.error !== null ? Promise.reject(res.error.message ? res.error.message : res.error) :
        res.data?.length === 1 ? Promise.resolve(res.data[0]) : Promise.reject('bad create data')
}

function updateResult<T>(res: Result<T[]>): Promise<T> {
    return res.error !== null ? Promise.reject(res.error.message ? res.error.message : res.error) :
        res.data?.length === 1 ? Promise.resolve(res.data[0]) : Promise.reject('bad update data')
}

function deleteResult<T>(res: Result<T[]>): Promise<void> {
    return res.error !== null ? Promise.reject(`Can't delete: ${res.error?.message}`) :
        res.data?.length === 1 ? Promise.resolve(undefined) : Promise.reject('bad delete data')
}

function isSample(p: Project): boolean {
    return p.id.startsWith('0000')
}
