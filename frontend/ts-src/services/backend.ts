import {errorToString} from "@azimutt/utils";
import {
    AzimuttSchema,
    ColumnRef,
    ColumnStats,
    DatabaseUrl,
    DatabaseQueryResults,
    TableId,
    TableStats
} from "@azimutt/database-types";
import {Logger} from "./logger";
import {
    buildProjectJson,
    computeStats,
    isLocal,
    isRemote,
    parseTableId,
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
    ProjectTokenId,
    ProjectVersion,
    ProjectVisibility
} from "../types/project";
import {Organization, OrganizationId, OrganizationSlug, Plan} from "../types/organization";
import {DateTime} from "../types/basics";
import * as Http from "../utils/http";
import {z} from "zod";
import {ZodType} from "zod/lib/types";
import * as Zod from "../utils/zod";
import * as Json from "../utils/json";
import * as jiff from "jiff";
import {CleverCloudResource} from "../types/clevercloud";
import {HerokuResource} from "../types/heroku";
import {TrackEvent} from "../types/tracking";

export class Backend {
    private projects: { [id: ProjectId]: ProjectJson } = {}

    constructor(private logger: Logger) {
    }

    loginUrl = (currentUrl: string | undefined): string =>
        currentUrl ? `/login/redirect?url=${encodeURIComponent(currentUrl)}` : '/login'

    getProject = async (o: OrganizationId, p: ProjectId, t: ProjectTokenId | null): Promise<ProjectInfoWithContent> => {
        this.logger.debug(`backend.getProject(${o}, ${p}, ${t})`)
        const project = await this.fetchProject(o, p, t)
        if (project.storage === ProjectStorage.enum.remote) {
            this.projects[p] = project.content
        }
        return project
    }

    private fetchProject = (o: OrganizationId, p: ProjectId, t: ProjectTokenId | null): Promise<ProjectInfoWithContent> => {
        const token = t ? `token=${t}&` : ''
        const path = `/api/v1/organizations/${o}/projects/${p}?${token}expand=organization,organization.plan,content`
        return Http.getJson(path, ProjectWithContentResponse, 'ProjectWithContentResponse').then(toProjectInfoWithContent)
    }

    createProjectLocal = (o: OrganizationId, json: ProjectJson): Promise<ProjectInfoLocal> => {
        this.logger.debug(`backend.createProjectLocal(${o})`, json)
        const path = `/api/v1/organizations/${o}/projects?expand=organization,organization.plan`
        return Http.postJson(path, toProjectBody(json, ProjectStorage.enum.local), ProjectResponse, 'ProjectResponse').then(toProjectInfo)
            .then(res => isLocal(res) ? res : Promise.reject('Expecting a local project'))
    }

    createProjectRemote = async (o: OrganizationId, json: ProjectJson): Promise<ProjectInfoRemote> => {
        this.logger.debug(`backend.createProjectRemote(${o})`, json)
        const path = `/api/v1/organizations/${o}/projects?expand=organization,organization.plan`
        const formData: FormData = new FormData()
        Object.entries(toProjectBody(json, ProjectStorage.enum.remote))
            .filter(([_, value]) => value !== null && value !== undefined)
            .map(([key, value]) => formData.append(key, typeof value === 'string' ? value : JSON.stringify(value)))
        formData.append('file', new Blob([encodeContent(json)], {type: 'application/json'}), `${json.name}.json`)
        const res = await Http.postMultipart(path, formData, ProjectResponse, 'ProjectResponse').then(toProjectInfo)
        this.projects[res.id] = json
        return isRemote(res) ? res : Promise.reject('Expecting a remote project')
    }

    updateProjectLocal = (p: Project): Promise<ProjectInfoLocal> => {
        this.logger.debug(`backend.updateProjectLocal(${p.organization?.id}, ${p.id})`, p)
        if (!p.organization) return Promise.reject('Expecting an organization to update project')
        if (p.storage !== ProjectStorage.enum.local) return Promise.reject('Expecting a local project')
        const path = `/api/v1/organizations/${p.organization.id}/projects/${p.id}?expand=organization,organization.plan`
        const json = buildProjectJson(p)
        return Http.putJson(path, toProjectBody(json, ProjectStorage.enum.local), ProjectResponse, 'ProjectResponse').then(toProjectInfo)
            .then(res => isLocal(res) ? res : Promise.reject('Expecting a local project'))
    }

    updateProjectRemote = async (p: Project): Promise<ProjectInfoRemote> => {
        this.logger.debug(`backend.updateProjectRemote(${p.organization?.id}, ${p.id})`, p)
        if (!p.organization) return Promise.reject('Expecting an organization to update project')
        if (p.storage !== ProjectStorage.enum.remote) return Promise.reject('Expecting a remote project')

        const initial = this.projects[p.id] // where the user started
        const current = await this.fetchProject(p.organization.id, p.id, null) // server version
            .then(p => isRemote(p) ? p : Promise.reject('Expecting a remote project'))
        let json = buildProjectJson(p)
        if (current.updatedAt !== p.updatedAt) {
            try {
                // FIXME: fail most of the time because of current_layout conflict :(
                const patch = jiff.diff(initial, json) // compute changes made by user
                json = jiff.patch(patch, current.content) // apply changes made by user
            } catch (e) {
                console.warn('patch failed', e)
                return Promise.reject('already updated by someone else, please reload')
            }
        }

        if (!p.organization) return Promise.reject('Expecting an organization to update project')
        const path = `/api/v1/organizations/${p.organization.id}/projects/${p.id}?expand=organization,organization.plan`
        const formData: FormData = new FormData()
        Object.entries(toProjectBody(json, ProjectStorage.enum.remote))
            .filter(([_, value]) => value !== null && value !== undefined)
            .map(([key, value]) => formData.append(key, typeof value === 'string' ? value : JSON.stringify(value)))
        formData.append('file', new Blob([encodeContent(json)], {type: 'application/json'}), `${p.organization.id}-${p.name}.json`)
        const res = await Http.putMultipart(path, formData, ProjectResponse, 'ProjectResponse').then(toProjectInfo)
        this.projects[p.id] = json
        return isRemote(res) ? res : Promise.reject('Expecting a remote project')
    }

    deleteProject = async (o: OrganizationId, p: ProjectId): Promise<void> => {
        this.logger.debug(`backend.deleteProject(${o}, ${p})`)
        await Http.deleteNoContent(`/api/v1/organizations/${o}/projects/${p}`)
        delete this.projects[p]
    }

    trackEvent = (event: TrackEvent): void => {
        this.logger.debug(`backend.trackEvent(${JSON.stringify(event)})`)
        const eventWithUrl = {
            ...event,
            details: {
                ...event.details,
                $current_url: window.location.href,
                $lib: 'front'
            }
        }
        Http.postNoContent(`/api/v1/events`, eventWithUrl).then(_ => undefined)
    }

    getDatabaseSchema = async (database: DatabaseUrl): Promise<AzimuttSchema> => {
        this.logger.debug(`backend.getDatabaseSchema(${database})`)
        return this.gatewayPost(`/schema`, {url: database}, AzimuttSchema, 'AzimuttSchema')
    }

    runDatabaseQuery = async (database: DatabaseUrl, query: string): Promise<DatabaseQueryResults> => {
        this.logger.debug(`backend.runQuery(${database}, ${query})`)
        return this.gatewayPost(`/query`, {url: database, query}, DatabaseQueryResults, 'DatabaseQueryResults')
    }

    getTableStats = async (database: DatabaseUrl, id: TableId): Promise<TableStats> => {
        this.logger.debug(`backend.getTableStats(${database}, ${id})`)
        const {schema, table} = parseTableId(id)
        return this.gatewayPost(`/table-stats`, {url: database, schema, table}, TableStats, 'TableStats')
    }

    getColumnStats = async (database: DatabaseUrl, column: ColumnRef): Promise<ColumnStats> => {
        this.logger.debug(`backend.getColumnStats(${database}, ${JSON.stringify(column)})`)
        const {schema, table} = parseTableId(column.table)
        return this.gatewayPost(`/column-stats`, {url: database, schema, table, column: column.column}, ColumnStats, 'ColumnStats')
    }

    private gatewayPost = async <Body, Response>(path: string, body: Body, zod: ZodType<Response>, label: string): Promise<Response> => {
        const gateway_local = 'http://localhost:4177'
        return Http.postJson(`${gateway_local}/gateway${path}`, body, zod, label).catch(localErr => {
            return Http.postJson(`${window.gateway_url}/gateway${path}`, body, zod, label).catch(remoteErr => {
                return Promise.reject(`${gateway_local}: ${errorToString(localErr)}\n${window.gateway_url}: ${errorToString(remoteErr)}`)
            })
        })
    }
}

export interface ProjectStatsResponse {
    nb_sources: number
    nb_tables: number
    nb_columns: number
    nb_relations: number
    nb_types: number
    nb_comments: number
    nb_layouts: number
    nb_notes: number
    nb_memos: number
}

export const ProjectStatsResponse = z.object({
    nb_sources: z.number(),
    nb_tables: z.number(),
    nb_columns: z.number(),
    nb_relations: z.number(),
    nb_types: z.number(),
    nb_comments: z.number(),
    nb_layouts: z.number(),
    nb_notes: z.number(),
    nb_memos: z.number()
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
    plan: Plan
    logo: string
    description: string | null
    clever_cloud?: CleverCloudResource
    heroku?: HerokuResource
}

export const OrganizationResponse = z.object({
    id: OrganizationId,
    slug: OrganizationSlug,
    name: z.string(),
    plan: Plan,
    logo: z.string(),
    description: z.string().nullable(),
    clever_cloud: CleverCloudResource.optional(),
    heroku: HerokuResource.optional(),
}).strict()

interface ProjectResponse extends ProjectStatsResponse {
    organization: OrganizationResponse
    id: ProjectId
    slug: ProjectSlug
    name: ProjectName
    description: string | null
    encoding_version: ProjectVersion
    storage_kind: ProjectStorage
    visibility: ProjectVisibility
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
    visibility: ProjectVisibility,
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
        nbLayouts: s.nb_layouts,
        nbNotes: s.nb_notes,
        nbMemos: s.nb_memos
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
        nb_layouts: s.nbLayouts,
        nb_notes: s.nbNotes,
        nb_memos: s.nbMemos
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
        plan: o.plan,
        logo: o.logo,
        description: o.description || undefined,
        clever_cloud: o.clever_cloud,
        heroku: o.heroku,
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
        visibility: p.visibility,
        createdAt: new Date(p.created_at).getTime(),
        updatedAt: new Date(p.updated_at).getTime(),
        ...toStats(p)
    }
}

function toProjectInfoWithContent(p: ProjectWithContentResponse): ProjectInfoWithContent {
    const res = toProjectInfo(p)
    return res.storage === ProjectStorage.enum.remote ? {...res, content: decodeContent(p.content)} : res
}

function encodeContent(p: ProjectJson): string {
    return Zod.stringify(p, ProjectJson, 'ProjectJson')
}

function decodeContent(content?: string): ProjectJson {
    if (typeof content === 'string') {
        return Zod.validate(Json.parse(content), ProjectJson, 'ProjectJson')
    } else {
        throw 'Missing content in backend response!'
    }
}
