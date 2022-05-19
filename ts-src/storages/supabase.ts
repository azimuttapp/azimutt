import {computeRelations, computeTables} from "./api";
import {SupabaseClient} from "@supabase/supabase-js";
import {Project, ProjectId, ProjectInfo, ProjectStorage} from "../types/project";
import {PostgrestError} from "@supabase/postgrest-js/src/lib/types";

const db = {
    projects: {
        table: 'projects',
    },
    projectAccesses: {
        table: 'project_accesses',
    }
}

export class SupabaseStorage {
    constructor(private supabase: SupabaseClient) {
    }

    listProjects = async (): Promise<ProjectInfo[]> => {
        const projects = await this.supabase.from(db.projects.table)
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
        const project = await this.supabase.from(db.projects.table)
            .select('project').match({id}).maybeSingle().then(resultToPromiseOpt)
        return project ? project.project : Promise.reject(`Not found`)
    }
    createProject = async (p: Project): Promise<Project> => {
        // if (isSample(p)) {
        //     return Promise.reject("Sample projects can't be uploaded!")
        // }
        const now = Date.now()
        const prj = {...p, createdAt: now, updatedAt: now} // TODO: fix with backend dates
        return await this.supabase.from(db.projects.table).insert({
            id: p.id,
            name: p.name,
            tables: computeTables(p.sources),
            relations: computeRelations(p.sources),
            layouts: Object.keys(p.layouts).length,
            project: p,
        }, {returning: 'minimal'}).then(checkResult).then(_ => prj)
    }
    updateProject = async (p: Project): Promise<Project> => {
        const prj = {...p, updatedAt: Date.now()} // TODO: fix with backend dates
        return await this.supabase.from(db.projects.table).update({
            name: p.name,
            tables: computeTables(p.sources),
            relations: computeRelations(p.sources),
            layouts: Object.keys(p.layouts).length,
            project: p,
            // FIXME update updated_at & updated_by: https://github.com/supabase/supabase/issues/379#issuecomment-1005614974
            // FIXME prevent edit other fields: https://dev.to/jdgamble555/supabase-date-protection-on-postgresql-1n91
        }).match({id: p.id}).then(checkResult).then(_ => prj)
    }
    dropProject = async (p: ProjectInfo): Promise<void> => {
        return await this.supabase.from(db.projects.table).delete()
            .match({id: p.id}).then(checkDelete)
    }
}

type ProjectAccess = 'none' | 'read' | 'write'
const ProjectAccess: {[key in ProjectAccess]: key} = {
    none: 'none',
    read: 'read',
    write: 'write'
}

type Result<T> = { data: T | null; error: Error | PostgrestError | null }

function resultToPromise<T>(res: Result<T>): Promise<T> {
    return res.error ? Promise.reject(res.error.message ? res.error.message : res.error) :
        res.data === null ? Promise.reject('Null data in supabase response') :
            Promise.resolve(res.data)
}

function resultToPromiseOpt<T>(res: Result<T>): Promise<T | null> {
    return res.error ? Promise.reject(res.error.message ? res.error.message : res.error) :
            Promise.resolve(res.data)
}

function checkResult<T>(res: Result<T>): Promise<void> {
    return res.error === null ? Promise.resolve(undefined) : Promise.reject(res.error.message ? res.error.message : res.error)
}

function checkDelete<T>(res: Result<T[]>): Promise<void> {
    return res.error === null && res.data?.length === 1 ? Promise.resolve(undefined) : Promise.reject(`Can't delete: ${res.error?.message}`)
}

function isSample(p: Project): boolean {
    return p.id.startsWith('0000')
}
