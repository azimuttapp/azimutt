import {z, ZodType} from "zod";
import {errorToString} from "@azimutt/utils";
import {
    AttributeRef,
    DatabaseUrl,
    DateTime,
    EntityRef,
    legacyBuildProjectJson,
    LegacyCleverCloudResource,
    legacyColumnPathSeparator,
    LegacyColumnStats,
    legacyComputeStats,
    LegacyDatabase,
    LegacyDatabaseQueryResults,
    LegacyHerokuResource,
    legacyIsLocal,
    legacyIsRemote,
    LegacyOrganization,
    LegacyOrganizationId,
    LegacyOrganizationSlug,
    LegacyPlan,
    LegacyProject,
    LegacyProjectId,
    LegacyProjectInfo,
    LegacyProjectInfoLocal,
    LegacyProjectInfoRemote,
    LegacyProjectInfoWithContent,
    LegacyProjectJson,
    LegacyProjectName,
    LegacyProjectSlug,
    LegacyProjectStats,
    LegacyProjectStorage,
    LegacyProjectTokenId,
    LegacyProjectVersion,
    LegacyProjectVisibility,
    LegacyTableStats,
    Uuid,
    zodParse,
    zodStringify
} from "@azimutt/models";
import {TrackEvent} from "../types/tracking";
import * as Http from "../utils/http";
import * as Json from "../utils/json";
import {Logger} from "./logger";
import * as jiff from "jiff";

export class Backend {
    private projects: { [id: LegacyProjectId]: LegacyProjectJson } = {}

    constructor(private logger: Logger) {
    }

    loginUrl = (currentUrl: string | undefined): string =>
        currentUrl ? `/login/redirect?url=${encodeURIComponent(currentUrl)}` : '/login'

    getCurrentUser = async (): Promise<UserResponse | undefined> =>
        Http.getJson(`/api/v1/users/current`, UserResponse).catch(err => err.statusCode === 401 ? undefined : Promise.reject(err))

    getProject = async (o: LegacyOrganizationId, p: LegacyProjectId, t: LegacyProjectTokenId | null): Promise<LegacyProjectInfoWithContent> => {
        this.logger.debug(`backend.getProject(${o}, ${p}, ${t})`)
        const project = await this.fetchProject(o, p, t)
        if (project.storage === LegacyProjectStorage.enum.remote) {
            this.projects[p] = project.content
        }
        return project
    }

    private fetchProject = async (o: LegacyOrganizationId, p: LegacyProjectId, t: LegacyProjectTokenId | null): Promise<LegacyProjectInfoWithContent> => {
        const token = t ? `token=${t}&` : ''
        const path = `/api/v1/organizations/${o}/projects/${p}?${token}expand=organization,organization.plan,content`
        return Http.getJson(path, ProjectWithContentResponse).then(toProjectInfoWithContent)
    }

    createProjectLocal = async (o: LegacyOrganizationId, json: LegacyProjectJson): Promise<LegacyProjectInfoLocal> => {
        this.logger.debug(`backend.createProjectLocal(${o})`, json)
        const path = `/api/v1/organizations/${o}/projects?expand=organization,organization.plan`
        return Http.postJson(path, toProjectBody(json, LegacyProjectStorage.enum.local), ProjectResponse).then(toProjectInfo)
            .then(res => legacyIsLocal(res) ? res : Promise.reject('Expecting a local project'))
    }

    createProjectRemote = async (o: LegacyOrganizationId, json: LegacyProjectJson): Promise<LegacyProjectInfoRemote> => {
        this.logger.debug(`backend.createProjectRemote(${o})`, json)
        const path = `/api/v1/organizations/${o}/projects?expand=organization,organization.plan`
        const formData: FormData = new FormData()
        Object.entries(toProjectBody(json, LegacyProjectStorage.enum.remote))
            .filter(([_, value]) => value !== null && value !== undefined)
            .map(([key, value]) => formData.append(key, typeof value === 'string' ? value : JSON.stringify(value)))
        formData.append('file', new Blob([encodeContent(json)], {type: 'application/json'}), `${json.name}.json`)
        const res = await Http.postMultipart(path, formData, ProjectResponse).then(toProjectInfo)
        this.projects[res.id] = json
        return legacyIsRemote(res) ? res : Promise.reject('Expecting a remote project')
    }

    updateProjectLocal = async (p: LegacyProject): Promise<LegacyProjectInfoLocal> => {
        this.logger.debug(`backend.updateProjectLocal(${p.organization?.id}, ${p.id})`, p)
        if (!p.organization) return Promise.reject('Expecting an organization to update project')
        if (p.storage !== LegacyProjectStorage.enum.local) return Promise.reject('Expecting a local project')
        const path = `/api/v1/organizations/${p.organization.id}/projects/${p.id}?expand=organization,organization.plan`
        const json = legacyBuildProjectJson(p)
        return Http.putJson(path, toProjectBody(json, LegacyProjectStorage.enum.local), ProjectResponse).then(toProjectInfo)
            .then(res => legacyIsLocal(res) ? res : Promise.reject('Expecting a local project'))
    }

    updateProjectRemote = async (p: LegacyProject): Promise<LegacyProjectInfoRemote> => {
        this.logger.debug(`backend.updateProjectRemote(${p.organization?.id}, ${p.id})`, p)
        if (!p.organization) return Promise.reject('Expecting an organization to update project')
        if (p.storage !== LegacyProjectStorage.enum.remote) return Promise.reject('Expecting a remote project')

        const initial = this.projects[p.id] // where the user started
        const current = await this.fetchProject(p.organization.id, p.id, null) // server version
            .then(p => legacyIsRemote(p) ? p : Promise.reject('Expecting a remote project'))
        let json = legacyBuildProjectJson(p)
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
        Object.entries(toProjectBody(json, LegacyProjectStorage.enum.remote))
            .filter(([_, value]) => value !== null && value !== undefined)
            .map(([key, value]) => formData.append(key, typeof value === 'string' ? value : JSON.stringify(value)))
        formData.append('file', new Blob([encodeContent(json)], {type: 'application/json'}), `${p.organization.id}-${p.name}.json`)
        const res = await Http.putMultipart(path, formData, ProjectResponse).then(toProjectInfo)
        this.projects[p.id] = json
        return legacyIsRemote(res) ? res : Promise.reject('Expecting a remote project')
    }

    deleteProject = async (o: LegacyOrganizationId, p: LegacyProjectId): Promise<void> => {
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

    getDatabaseSchema = async (database: DatabaseUrl): Promise<LegacyDatabase> => {
        this.logger.debug(`backend.getDatabaseSchema(${database})`)
        const user = await this.getCurrentUser()
        return this.gatewayPost(`/schema`, {url: database, user: user?.email}, LegacyDatabase)
    }

    runDatabaseQuery = async (database: DatabaseUrl, query: string): Promise<LegacyDatabaseQueryResults> => {
        this.logger.debug(`backend.runQuery(${database}, ${query})`)
        const user = await this.getCurrentUser()
        return this.gatewayPost(`/query`, {url: database, query, user: user?.email}, LegacyDatabaseQueryResults)
    }

    getTableStats = async (database: DatabaseUrl, entity: EntityRef): Promise<LegacyTableStats> => {
        this.logger.debug(`backend.getTableStats(${database}, ${JSON.stringify(entity)})`)
        const user = await this.getCurrentUser()
        return this.gatewayPost(`/table-stats`, {
            url: database,
            schema: entity.schema,
            table: entity.entity,
            user: user?.email,
        }, LegacyTableStats)
    }

    getColumnStats = async (database: DatabaseUrl, attribute: AttributeRef): Promise<LegacyColumnStats> => {
        this.logger.debug(`backend.getColumnStats(${database}, ${JSON.stringify(attribute)})`)
        const user = await this.getCurrentUser()
        return this.gatewayPost(`/column-stats`, {
            url: database,
            schema: attribute.schema,
            table: attribute.entity,
            column: attribute.attribute.join(legacyColumnPathSeparator),
            user: user?.email,
        }, LegacyColumnStats)
    }

    private gatewayPost = async <Body, Response>(path: string, body: Body, zod: ZodType<Response>): Promise<Response> => {
        const gateway_local = 'http://localhost:4177'
        const now = Date.now()
        return Http.getJson(`${gateway_local}/ping?time=${now}`, GatewayPing, {cache: 'no-store'}).then(_ => {
            return Http.postJson(`${gateway_local}/gateway${path}`, body, zod)
                .catch(err => Promise.reject(`Local gateway: ${errorToString(err)}`))
        }, _ => {
            const gateway_remote = window.gateway_url || ''
            return Http.getJson(`${gateway_remote}/ping?time=${now}`, GatewayPing, {cache: 'no-store'})
                .then(_ => Http.postJson(`${gateway_remote}/gateway${path}`, body, zod))
                .catch(err => Promise.reject(`${gateway_remote.includes('azimutt.app') ? 'Azimutt gateway' : 'Custom gateway'}: ${errorToString(err)}, forgot to start the local gateway? (npx azimutt@latest gateway)`))
        })
    }
}

export const UserResponse = z.object({
    id: Uuid,
    slug: z.string(),
    name: z.string(),
    email: z.string(),
    avatar: z.string(),
    github_username: z.string().nullish(),
    twitter_username: z.string().nullish(),
    is_admin: z.boolean(),
    last_signin: DateTime,
    created_at: DateTime,
}).strict().describe('UserResponse')
export type UserResponse = z.infer<typeof UserResponse>

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
    name: LegacyProjectName
    description: string | undefined
    storage_kind: LegacyProjectStorage
    encoding_version: number
}

export interface OrganizationResponse {
    id: LegacyOrganizationId
    slug: LegacyOrganizationSlug
    name: string
    plan: LegacyPlan
    logo: string
    description: string | null
    clever_cloud?: LegacyCleverCloudResource
    heroku?: LegacyHerokuResource
}

export const OrganizationResponse = z.object({
    id: LegacyOrganizationId,
    slug: LegacyOrganizationSlug,
    name: z.string(),
    plan: LegacyPlan,
    logo: z.string(),
    description: z.string().nullable(),
    clever_cloud: LegacyCleverCloudResource.optional(),
    heroku: LegacyHerokuResource.optional(),
}).strict()

interface ProjectResponse extends ProjectStatsResponse {
    organization: OrganizationResponse
    id: LegacyProjectId
    slug: LegacyProjectSlug
    name: LegacyProjectName
    description: string | null
    encoding_version: LegacyProjectVersion
    storage_kind: LegacyProjectStorage
    visibility: LegacyProjectVisibility
    created_at: DateTime
    updated_at: DateTime
    archived_at: DateTime | null
}

export const ProjectResponse = ProjectStatsResponse.extend({
    organization: OrganizationResponse,
    id: LegacyProjectId,
    slug: LegacyProjectSlug,
    name: LegacyProjectName,
    description: z.string().nullable(),
    encoding_version: LegacyProjectVersion,
    storage_kind: LegacyProjectStorage,
    visibility: LegacyProjectVisibility,
    created_at: DateTime,
    updated_at: DateTime,
    archived_at: DateTime.nullable()
}).strict().describe('ProjectResponse')

interface ProjectWithContentResponse extends ProjectResponse {
    content?: string
}

export const ProjectWithContentResponse = ProjectResponse.extend({
    content: z.string().optional()
}).strict().describe('ProjectWithContentResponse')

const GatewayPing = z.object({
    status: z.literal(200)
}).strict()
export type GatewayPing = z.infer<typeof GatewayPing>

function toStats(s: ProjectStatsResponse): LegacyProjectStats {
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

function toStatsResponse(s: LegacyProjectStats): ProjectStatsResponse {
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

function toProjectBody(p: LegacyProjectJson, storage: LegacyProjectStorage): ProjectBody {
    return {
        name: p.name,
        description: undefined,
        storage_kind: storage,
        encoding_version: p.version,
        ...toStatsResponse(legacyComputeStats(p))
    }
}

function toOrganization(o: OrganizationResponse): LegacyOrganization {
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

function toProjectInfo(p: ProjectResponse): LegacyProjectInfo {
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

function toProjectInfoWithContent(p: ProjectWithContentResponse): LegacyProjectInfoWithContent {
    const res = toProjectInfo(p)
    return res.storage === LegacyProjectStorage.enum.remote ? {...res, content: decodeContent(p.content)} : res
}

function encodeContent(p: LegacyProjectJson): string {
    return zodStringify(LegacyProjectJson)(p)
}

function decodeContent(content?: string): LegacyProjectJson {
    if (typeof content === 'string') {
        return zodParse(LegacyProjectJson)(Json.parse(content)).getOrThrow()
    } else {
        throw 'Missing content in backend response!'
    }
}
