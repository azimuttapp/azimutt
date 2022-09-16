import {Logger} from "./logger";
import {
    Project,
    ProjectId,
    ProjectInfo,
    ProjectName,
    ProjectNoStorage,
    ProjectSlug,
    ProjectStorage
} from "../types/project";
import {OrganizationId} from "../types/organization";
import {computeStats, ProjectStats} from "./storage/api";
import {DateTime} from "../types/basics";
import * as Http from "../utils/http";
import jiff from "jiff";

export class Backend {
    constructor(private logger: Logger) {
    }

    createProjectLocal = (o: OrganizationId, p: Project): Promise<ProjectInfo> => {
        return Http.postJson<CreateLocalProjectPayload, CreateProjectResponse>(`/api/v1/organizations/${o}/projects`, {
            name: p.name,
            description: undefined,
            storage_kind: ProjectStorage.local,
            encoding_version: p.version,
            ...computeStats(p)
        }).then(res => {
            return {
                id: res.json.id,
                name: res.json.name,
                tables: res.json.nb_tables,
                relations: res.json.nb_relations,
                layouts: res.json.nb_layouts,
                storage: res.json.storage_kind,
                createdAt: new Date(res.json.created_at).getTime(),
                updatedAt: new Date(res.json.updated_at).getTime()
            }
        })
    }
    createProjectRemote = (o: OrganizationId, p: Project): Promise<ProjectInfo> => {
        return Promise.reject('not implemented')
    }

    // updateProject = async (id: ProjectId, p: ProjectNoStorage): Promise<ProjectNoStorage> => {
    //     const initial = this.projects[id]
    //     const current = await this.get<ProjectNoStorage>(`/projects/${id}`)
    //     if (initial.updatedAt !== current.updatedAt) {
    //         try {
    //             const patch = jiff.diff(initial, p)
    //             p = jiff.patch(patch, current)
    //         } catch (e) {
    //             console.warn('patch failed', e)
    //             return Promise.reject("Project has been updated by another user! Please reload and save again (you will have to do you changes again).")
    //         }
    //     }
    //     await this.put(`/projects/${id}`, {
    //         id: id,
    //         name: p.name,
    //         tables: 0,
    //         relations: 0,
    //         layouts: Object.keys(p.layouts).length,
    //         project: p
    //     })
    //     this.projects[id] = p
    //     return p
    // }

    deleteProject = (o: OrganizationId, p: ProjectId): Promise<void> => {
        return Http.deleteNoContent(`/api/v1/organizations/${o}/projects/${p}`).then(_ => undefined)
    }
}

interface CreateLocalProjectPayload extends ProjectStats {
    name: ProjectName
    description: string | undefined
    storage_kind: 'local'
    encoding_version: number
}

interface CreateProjectResponse extends ProjectStats {
    id: ProjectId
    slug: ProjectSlug
    name: ProjectName
    description: string | undefined
    encoding_version: number
    storage_kind: ProjectStorage
    created_at: DateTime
    updated_at: DateTime
    archived_at: DateTime | undefined
}
