import {Logger} from "./logger";
import {Project, ProjectId, ProjectInfo, ProjectName, ProjectSlug, ProjectStorage} from "../types/project";
import {OrganizationId} from "../types/organization";
import {computeStats, ProjectStats} from "../storages/api";
import {DateTime} from "../types/basics";
import * as Http from "../utils/http";

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
