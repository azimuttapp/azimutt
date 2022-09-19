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
    ProjectVersion,
    validStorage
} from "../types/project";
import {Organization, OrganizationId, OrganizationSlug, validPlan} from "../types/organization";
import {DateTime} from "../types/basics";
import {Env} from "../utils/env";
import * as Http from "../utils/http";

function buildPayload(p: ProjectJson, storage: ProjectStorage): CreateProjectPayload {
    return {
        name: p.name,
        description: undefined,
        storage_kind: storage,
        encoding_version: p.version,
        ...adaptStats(computeStats(p))
    }
}

export class Backend {
    constructor(private env: Env, private logger: Logger) {
    }

    getProject = (o: OrganizationId, p: ProjectId): Promise<ProjectInfoWithContent> => {
        this.logger.debug(`backend.getProject(${o}, ${p})`)
        const url = this.withXhrHost(`/api/v1/organizations/${o}/projects/${p}?expand=organization,content`)
        return Http.getJson<ProjectWithOrgaContentResponse>(url).then(res => formatProjectResponseWithContent(res.json))
    }

    createProjectLocal = (o: OrganizationId, p: ProjectJson): Promise<ProjectInfoLocal> => {
        this.logger.debug(`backend.createProjectLocal(${o})`, p)
        const url = this.withXhrHost(`/api/v1/organizations/${o}/projects?expand=organization`)
        return Http.postJson<CreateProjectPayload, ProjectWithOrgaResponse>(url, buildPayload(p, ProjectStorage.local))
            .then(res => formatProjectResponse(res.json))
            .then(res => isLocal(res) ? res : Promise.reject('Expecting a local project'))
    }

    createProjectRemote = (o: OrganizationId, p: ProjectJson): Promise<ProjectInfoRemote> => {
        this.logger.debug(`backend.createProjectRemote(${o})`, p)
        const url = this.withXhrHost(`/api/v1/organizations/${o}/projects?expand=organization`)
        const formData: FormData = new FormData()
        Object.entries(buildPayload(p, ProjectStorage.remote))
            .filter(([_, value]) => value !== null && value !== undefined)
            .map(([key, value]) => formData.append(key, typeof value === 'string' ? value : JSON.stringify(value)))
        formData.append('file', new Blob([JSON.stringify(p)], {type: 'application/json'}), `${o}-${p.name}.json`) // FIXME remove filename
        return Http.postMultipart<ProjectWithOrgaResponse>(url, formData)
            .then(res => formatProjectResponse(res.json))
            .then(res => isRemote(res) ? res : Promise.reject('Expecting a remote project'))
    }

    updateProjectLocal = (p: Project): Promise<ProjectInfoLocal> => {
        this.logger.debug(`backend.updateProjectLocal(${p.organization.id}, ${p.id})`, p)
        const url = this.withXhrHost(`/api/v1/organizations/${p.organization.id}/projects/${p.id}?expand=organization`)
        return Http.putJson<CreateProjectPayload, ProjectWithOrgaResponse>(url, buildPayload(buildProjectJson(p), ProjectStorage.local))
            .then(res => formatProjectResponse(res.json))
            .then(res => isLocal(res) ? res : Promise.reject('Expecting a local project'))
    }

    updateProjectRemote = (p: Project): Promise<ProjectInfoRemote> => {
        this.logger.debug(`backend.updateProjectRemote(${p.organization.id}, ${p.id})`, p)
        const url = this.withXhrHost(`/api/v1/organizations/${p.organization.id}/projects/${p.id}?expand=organization`)
        const formData: FormData = new FormData()
        Object.entries(buildPayload(buildProjectJson(p), ProjectStorage.remote))
            .filter(([_, value]) => value !== null && value !== undefined)
            .map(([key, value]) => formData.append(key, typeof value === 'string' ? value : JSON.stringify(value)))
        formData.append('file', new Blob([JSON.stringify(p)], {type: 'application/json'}), `${p.organization.id}-${p.name}.json`)
        return Http.putMultipart<ProjectWithOrgaResponse>(url, formData)
            .then(res => formatProjectResponse(res.json))
            .then(res => isRemote(res) ? res : Promise.reject('Expecting a remote project'))
    }

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

interface CreateProjectPayload extends ProjectStatsResponse {
    name: ProjectName
    description: string | undefined
    storage_kind: ProjectStorage
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
        description: p.description || undefined,
        encodingVersion: p.encoding_version,
        storage: validStorage(p.storage_kind),
        createdAt: new Date(p.created_at).getTime(),
        updatedAt: new Date(p.updated_at).getTime(),
        ...formatStats(p)
    }
}

function formatProjectResponseWithContent(p: ProjectWithOrgaContentResponse): ProjectInfoWithContent {
    const res = formatProjectResponse(p)
    return res.storage === ProjectStorage.remote ? {...res, content: decodeContent(p)} : res
}

function decodeContent(p: ProjectWithOrgaContentResponse): ProjectJson {
    if (typeof p.content === 'string') {
        return JSON.parse(p.content)
    } else {
        throw 'Missing content in backend response!'
    }
}

function formatOrganizationResponse(o: OrganizationResponse): Organization {
    return {
        id: o.id,
        slug: o.slug,
        name: o.name,
        activePlan: validPlan(o.active_plan),
        logo: o.logo,
        location: o.location,
        description: o.description
    }
}
