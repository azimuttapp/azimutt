import {Logger} from "./logger";
import {
    computeStats,
    Project,
    ProjectId,
    ProjectInfo,
    ProjectInfoWithContent,
    ProjectName,
    ProjectSlug,
    ProjectStats,
    ProjectStorage,
    ProjectVersion
} from "../types/project";
import {Organization, OrganizationId, OrganizationSlug} from "../types/organization";
import {DateTime} from "../types/basics";
import {Env} from "../utils/env";
import * as Http from "../utils/http";
import jiff from "jiff";

export class Backend {
    constructor(private env: Env, private logger: Logger) {
    }

    getProject = (o: OrganizationId, p: ProjectId): Promise<ProjectInfoWithContent> => {
        this.logger.debug(`backend.getProject(${o}, ${p})`)
        const url = this.withXhrHost(`/api/v1/organizations/${o}/projects/${p}?expand=organization,content`)
        return Http.getJson<ProjectWithOrgaContentResponse>(url)
            .then(res => ({...formatProjectResponse(res.json), content: res.json.content}))
    }

    createProjectLocal = (o: OrganizationId, p: Project): Promise<ProjectInfo> => {
        this.logger.debug(`backend.createProjectLocal(${o})`, p)
        const url = this.withXhrHost(`/api/v1/organizations/${o}/projects?expand=organization`)
        return Http.postJson<CreateLocalProjectPayload, ProjectWithOrgaResponse>(url, {
            name: p.name,
            description: undefined,
            storage_kind: ProjectStorage.local,
            encoding_version: p.version,
            ...adaptStats(computeStats(p))
        }).then(res => formatProjectResponse(res.json))
    }
    createProjectRemote = (o: OrganizationId, p: Project): Promise<ProjectInfo> => {
        this.logger.debug(`backend.createProjectRemote(${o})`, p)
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
    //             this.logger.warn('patch failed', e)
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
        this.logger.debug(`backend.deleteProject(${o}, ${p})`)
        const url = this.withXhrHost(`/api/v1/organizations/${o}/projects/${p}`)
        return Http.deleteNoContent(url).then(_ => undefined)
    }

    private withXhrHost(path: string): string {
        if (this.env == Env.dev) {
            return `${path}`
        } else if (this.env == Env.staging) {
            return `https://azimutt.dev${path}`
        } else {
            return `https://azimutt.app${path}`
        }
    }
}

export interface ProjectStatsResponse {
    nb_sources: number
    nb_tables: number
    nb_columns: number
    nb_relations: number
    nb_types: number
    nb_comments: number
    nb_notes: number
    nb_layouts: number
}

interface CreateLocalProjectPayload extends ProjectStatsResponse {
    name: ProjectName
    description: string | undefined
    storage_kind: 'local'
    encoding_version: number
}

interface ProjectResponse extends ProjectStatsResponse {
    id: ProjectId
    slug: ProjectSlug
    name: ProjectName
    description: string | null
    encoding_version: ProjectVersion
    storage_kind: ProjectStorage
    created_at: DateTime
    updated_at: DateTime
    archived_at: DateTime | null
}

interface ProjectWithOrgaResponse extends ProjectResponse {
    organization: OrganizationResponse
}

interface ProjectWithOrgaContentResponse extends ProjectResponse {
    organization: OrganizationResponse
    content: string | undefined
}

export interface OrganizationResponse {
    id: OrganizationId
    slug: OrganizationSlug
    name: string
    active_plan: string
    logo: string
    location: string | null
    description: string | null
}

function adaptStats(s: ProjectStats): ProjectStatsResponse {
    return {
        nb_sources: s.nbSources,
        nb_tables: s.nbTables,
        nb_columns: s.nbColumns,
        nb_relations: s.nbRelations,
        nb_types: s.nbTypes,
        nb_comments: s.nbComments,
        nb_notes: s.nbNotes,
        nb_layouts: s.nbLayouts
    }
}

function formatStats(s: ProjectStatsResponse): ProjectStats {
    return {
        nbSources: s.nb_sources,
        nbTables: s.nb_tables,
        nbColumns: s.nb_columns,
        nbRelations: s.nb_relations,
        nbTypes: s.nb_types,
        nbComments: s.nb_comments,
        nbNotes: s.nb_notes,
        nbLayouts: s.nb_layouts
    }
}

function formatProjectResponse(p: ProjectWithOrgaResponse): ProjectInfo {
    return {
        organization: formatOrganizationResponse(p.organization),
        id: p.id,
        slug: p.slug,
        name: p.name,
        description: p.description,
        encodingVersion: p.encoding_version,
        storage: p.storage_kind,
        createdAt: new Date(p.created_at).getTime(),
        updatedAt: new Date(p.updated_at).getTime(),
        archivedAt: p.archived_at ? new Date(p.archived_at).getTime() : null,
        ...formatStats(p)
    }
}

function formatOrganizationResponse(o: OrganizationResponse): Organization {
    return {
        id: o.id,
        slug: o.slug,
        name: o.name,
        activePlan: o.active_plan,
        logo: o.logo,
        location: o.location,
        description: o.description
    }
}
