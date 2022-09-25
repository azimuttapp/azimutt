import {Logger} from "./logger";
import {
    buildProjectJson,
    computeStats,
    isLocal,
    isRemote,
    Project,
    ProjectId,
    ProjectInfo,
    ProjectInfoLocal,
    ProjectInfoRemote,
    ProjectInfoWithContent,
    ProjectJson,
    ProjectName,
    ProjectSlug,
    ProjectStats,
    ProjectStorage,
    ProjectVersion
} from "../types/project";
import {Organization, OrganizationId, OrganizationPlan, OrganizationSlug} from "../types/organization";
import {DateTime} from "../types/basics";
import {Env} from "../utils/env";
import * as Http from "../utils/http";
import {z} from "zod";
import * as Zod from "../utils/zod";
import * as Json from "../utils/json";


export class Backend {
    constructor(private env: Env, private logger: Logger) {
    }

    getProject = (o: OrganizationId, p: ProjectId): Promise<ProjectInfoWithContent> => {
        this.logger.debug(`backend.getProject(${o}, ${p})`)
        const url = this.withXhrHost(`/api/v1/organizations/${o}/projects/${p}?expand=organization,content`)
        return Http.getJson(url, ProjectWithContentResponse, 'ProjectWithContentResponse').then(toProjectInfoWithContent)
    }

    createProjectLocal = (o: OrganizationId, p: ProjectJson): Promise<ProjectInfoLocal> => {
        this.logger.debug(`backend.createProjectLocal(${o})`, p)
        const url = this.withXhrHost(`/api/v1/organizations/${o}/projects?expand=organization`)
        return Http.postJson(url, toProjectBody(p, ProjectStorage.enum.local), ProjectResponse, 'ProjectResponse').then(toProjectInfo)
            .then(res => isLocal(res) ? res : Promise.reject('Expecting a local project'))
    }

    createProjectRemote = (o: OrganizationId, p: ProjectJson): Promise<ProjectInfoRemote> => {
        this.logger.debug(`backend.createProjectRemote(${o})`, p)
        const url = this.withXhrHost(`/api/v1/organizations/${o}/projects?expand=organization`)
        const formData: FormData = new FormData()
        Object.entries(toProjectBody(p, ProjectStorage.enum.remote))
            .filter(([_, value]) => value !== null && value !== undefined)
            .map(([key, value]) => formData.append(key, typeof value === 'string' ? value : JSON.stringify(value)))
        formData.append('file', new Blob([JSON.stringify(p)], {type: 'application/json'}), `${p.name}.json`)
        return Http.postMultipart(url, formData, ProjectResponse, 'ProjectResponse').then(toProjectInfo)
            .then(res => isRemote(res) ? res : Promise.reject('Expecting a remote project'))
    }

    updateProjectLocal = (p: Project): Promise<ProjectInfoLocal> => {
        this.logger.debug(`backend.updateProjectLocal(${p.organization?.id}, ${p.id})`, p)
        if(!p.organization) return Promise.reject('Expecting an organization to update project')
        const url = this.withXhrHost(`/api/v1/organizations/${p.organization.id}/projects/${p.id}?expand=organization`)
        return Http.putJson(url, toProjectBody(buildProjectJson(p), ProjectStorage.enum.local), ProjectResponse, 'ProjectResponse').then(toProjectInfo)
            .then(res => isLocal(res) ? res : Promise.reject('Expecting a local project'))
    }

    updateProjectRemote = (p: Project): Promise<ProjectInfoRemote> => {
        this.logger.debug(`backend.updateProjectRemote(${p.organization?.id}, ${p.id})`, p)
        if(!p.organization) return Promise.reject('Expecting an organization to update project')
        const url = this.withXhrHost(`/api/v1/organizations/${p.organization.id}/projects/${p.id}?expand=organization`)
        const formData: FormData = new FormData()
        Object.entries(toProjectBody(buildProjectJson(p), ProjectStorage.enum.remote))
            .filter(([_, value]) => value !== null && value !== undefined)
            .map(([key, value]) => formData.append(key, typeof value === 'string' ? value : JSON.stringify(value)))
        formData.append('file', new Blob([JSON.stringify(p)], {type: 'application/json'}), `${p.organization.id}-${p.name}.json`)
        return Http.putMultipart(url, formData, ProjectResponse, 'ProjectResponse').then(toProjectInfo)
            .then(res => isRemote(res) ? res : Promise.reject('Expecting a remote project'))
    }

    deleteProject = (o: OrganizationId, p: ProjectId): Promise<void> => {
        this.logger.debug(`backend.deleteProject(${o}, ${p})`)
        const url = this.withXhrHost(`/api/v1/organizations/${o}/projects/${p}`)
        return Http.deleteNoContent(url)
    }

    private withXhrHost(path: string): string {
        if (this.env == Env.enum.dev) {
            return `${path}`
        } else if (this.env == Env.enum.staging) {
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

export const ProjectStatsResponse = z.object({
    nb_sources: z.number(),
    nb_tables: z.number(),
    nb_columns: z.number(),
    nb_relations: z.number(),
    nb_types: z.number(),
    nb_comments: z.number(),
    nb_notes: z.number(),
    nb_layouts: z.number()
}).strict()

interface ProjectBody extends ProjectStatsResponse {
    name: ProjectName
    description: string | undefined
    storage_kind: ProjectStorage
    encoding_version: number
}

export interface OrganizationResponse {
    id: OrganizationId
    slug: OrganizationSlug
    name: string
    active_plan: OrganizationPlan
    logo: string
    location: string | null
    description: string | null
}

export const OrganizationResponse = z.object({
    id: OrganizationId,
    slug: OrganizationSlug,
    name: z.string(),
    active_plan: OrganizationPlan,
    logo: z.string(),
    location: z.string().nullable(),
    description: z.string().nullable()
}).strict()

interface ProjectResponse extends ProjectStatsResponse {
    organization: OrganizationResponse
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

export const ProjectResponse = ProjectStatsResponse.extend({
    organization: OrganizationResponse,
    id: ProjectId,
    slug: ProjectSlug,
    name: ProjectName,
    description: z.string().nullable(),
    encoding_version: ProjectVersion,
    storage_kind: ProjectStorage,
    created_at: DateTime,
    updated_at: DateTime,
    archived_at: DateTime.nullable()
}).strict()

interface ProjectWithContentResponse extends ProjectResponse {
    content?: string
}

export const ProjectWithContentResponse = ProjectResponse.extend({
    content: z.string().optional()
}).strict()

function toStats(s: ProjectStatsResponse): ProjectStats {
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

function toStatsResponse(s: ProjectStats): ProjectStatsResponse {
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

function toProjectBody(p: ProjectJson, storage: ProjectStorage): ProjectBody {
    return {
        name: p.name,
        description: undefined,
        storage_kind: storage,
        encoding_version: p.version,
        ...toStatsResponse(computeStats(p))
    }
}

function toOrganization(o: OrganizationResponse): Organization {
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

function toProjectInfo(p: ProjectResponse): ProjectInfo {
    return {
        organization: toOrganization(p.organization),
        id: p.id,
        slug: p.slug,
        name: p.name,
        description: p.description || undefined,
        encodingVersion: p.encoding_version,
        storage: p.storage_kind,
        createdAt: new Date(p.created_at).getTime(),
        updatedAt: new Date(p.updated_at).getTime(),
        ...toStats(p)
    }
}

function toProjectInfoWithContent(p: ProjectWithContentResponse): ProjectInfoWithContent {
    const res = toProjectInfo(p)
    return res.storage === ProjectStorage.enum.remote ? {...res, content: decodeContent(p)} : res
}

function decodeContent(p: ProjectWithContentResponse): ProjectJson {
    if (typeof p.content === 'string') {
        return Zod.validate(Json.parse(p.content), ProjectJson, 'ProjectJson')
    } else {
        throw 'Missing content in backend response!'
    }
}
