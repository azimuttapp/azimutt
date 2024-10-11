import {z} from "zod";
import {groupBy, removeEmpty, removeUndefined} from "@azimutt/utils";
import {Color, Position, Size, Slug, Timestamp, Uuid} from "../common";
import {
    checkFromLegacy,
    columnValueFromLegacy,
    indexFromLegacy,
    LegacyColumnDbStats,
    LegacyColumnName,
    LegacyColumnType,
    LegacyJsValue,
    LegacyRelationName,
    LegacySchemaName,
    LegacyTableDbStats,
    LegacyTableId,
    LegacyTableName,
    LegacyTypeName,
    primaryKeyFromLegacy,
    relationFromLegacy,
    tableDbStatsFromLegacy,
    uniqueFromLegacy
} from "./legacyDatabase";
import {zodParse} from "../zod";
import {Attribute, Database, DatabaseKind, Entity, Type} from "../database";
import {parseDatabaseUrl} from "../databaseUrl";
import {OpenAIKey, OpenAIModel} from "../llm";

// MUST stay in sync with backend/lib/azimutt_web/utils/project_schema.ex

export type LegacyProjectId = Uuid
export const LegacyProjectId = Uuid
export type LegacyProjectSlug = Slug
export const LegacyProjectSlug = Slug
export type LegacyProjectName = string
export const LegacyProjectName = z.string()
export type LegacySourceId = Uuid
export const LegacySourceId = Uuid
export type LegacySourceName = string
export const LegacySourceName = z.string()
export type LegacyColumnPathStr = string
export const LegacyColumnPathStr = z.string()
export type LegacyLine = string
export const LegacyLine = z.string()
export type LegacyLineIndex = number
export const LegacyLineIndex = z.number()
export type LegacyTableRowId = number
export const LegacyTableRowId = z.number()
export type LegacyMemoId = number
export const LegacyMemoId = z.number()
export type LegacyLayoutName = string
export const LegacyLayoutName = z.string()
export type LegacyZoomLevel = number
export const LegacyZoomLevel = z.number()
export type LegacyProjectTokenId = Uuid
export const LegacyProjectTokenId = Uuid

export const DatabaseUrlStorage = z.enum(['memory', 'browser', 'project'])
export type DatabaseUrlStorage = z.infer<typeof DatabaseUrlStorage>

export const LegacyDatabaseConnection = z.object({
    kind: z.literal('DatabaseConnection'),
    engine: DatabaseKind.optional(),
    url: z.string().optional(),
    storage: DatabaseUrlStorage.optional(),
}).strict()
export type LegacyDatabaseConnection = z.infer<typeof LegacyDatabaseConnection>

export interface LegacySqlLocalFile {
    kind: 'SqlLocalFile',
    name: string,
    size: number,
    modified: Timestamp
}

export const LegacySqlLocalFile = z.object({
    kind: z.literal('SqlLocalFile'),
    name: z.string(),
    size: z.number(),
    modified: Timestamp
}).strict()

export interface LegacySqlRemoteFile {
    kind: 'SqlRemoteFile',
    url: string,
    size: number
}

export const LegacySqlRemoteFile = z.object({
    kind: z.literal('SqlRemoteFile'),
    url: z.string(),
    size: z.number()
}).strict()

export interface LegacyPrismaLocalFile {
    kind: 'PrismaLocalFile',
    name: string,
    size: number,
    modified: Timestamp
}

export const LegacyPrismaLocalFile = z.object({
    kind: z.literal('PrismaLocalFile'),
    name: z.string(),
    size: z.number(),
    modified: Timestamp
}).strict()

export interface LegacyPrismaRemoteFile {
    kind: 'PrismaRemoteFile',
    url: string,
    size: number
}

export const LegacyPrismaRemoteFile = z.object({
    kind: z.literal('PrismaRemoteFile'),
    url: z.string(),
    size: z.number()
}).strict()

export interface LegacyJsonLocalFile {
    kind: 'JsonLocalFile',
    name: string,
    size: number,
    modified: Timestamp
}

export const LegacyJsonLocalFile = z.object({
    kind: z.literal('JsonLocalFile'),
    name: z.string(),
    size: z.number(),
    modified: Timestamp
}).strict()

export interface LegacyJsonRemoteFile {
    kind: 'JsonRemoteFile',
    url: string,
    size: number
}

export const LegacyJsonRemoteFile = z.object({
    kind: z.literal('JsonRemoteFile'),
    url: z.string(),
    size: z.number()
}).strict()

export interface LegacyAmlEditor {
    kind: 'AmlEditor'
}

export const LegacyAmlEditor = z.object({
    kind: z.literal('AmlEditor')
}).strict()

export type LegacySourceKind = LegacyDatabaseConnection | LegacySqlLocalFile | LegacySqlRemoteFile | LegacyPrismaLocalFile | LegacyPrismaRemoteFile | LegacyJsonLocalFile | LegacyJsonRemoteFile | LegacyAmlEditor
export const LegacySourceKind = z.discriminatedUnion('kind', [LegacyDatabaseConnection, LegacySqlLocalFile, LegacySqlRemoteFile, LegacyPrismaLocalFile, LegacyPrismaRemoteFile, LegacyJsonLocalFile, LegacyJsonRemoteFile, LegacyAmlEditor])

export type LegacySourceOrigin = 'import-project' | 'sql-source' | 'prisma-source' | 'json-source'
export const LegacySourceOrigin = z.enum(['import-project', 'sql-source', 'prisma-source', 'json-source'])

export interface LegacyOrigin {
    id: LegacySourceId
    lines?: LegacyLineIndex[]
}

export const LegacyOrigin = z.object({
    id: LegacySourceId,
    lines: LegacyLineIndex.array().optional()
}).strict()

export interface LegacyComment {
    text: string
    origins?: LegacyOrigin[]
}

export const LegacyComment = z.object({
    text: z.string(),
    origins: LegacyOrigin.array().optional()
}).strict()

export interface LegacyProjectColumn {
    name: LegacyColumnName
    type: LegacyColumnType
    nullable?: boolean
    default?: string
    comment?: LegacyComment
    values?: string[]
    columns?: LegacyProjectColumn[]
    stats?: LegacyColumnDbStats
    origins?: LegacyOrigin[]
}

export const LegacyProjectColumn: z.ZodType<LegacyProjectColumn> = z.object({
    name: LegacyColumnName,
    type: LegacyColumnType,
    nullable: z.boolean().optional(),
    default: z.string().optional(),
    comment: LegacyComment.optional(),
    values: z.string().array().optional(),
    columns: z.lazy(() => LegacyProjectColumn.array().optional()),
    stats: LegacyColumnDbStats.optional(),
    origins: LegacyOrigin.array().optional()
}).strict()

export interface LegacyProjectPrimaryKey {
    name?: string
    columns: LegacyColumnName[]
    origins?: LegacyOrigin[]
}

export const LegacyProjectPrimaryKey = z.object({
    name: z.string().optional(),
    columns: LegacyColumnName.array(),
    origins: LegacyOrigin.array().optional()
}).strict()

export interface LegacyProjectUnique {
    name: string
    columns: LegacyColumnName[]
    definition?: string
    origins?: LegacyOrigin[]
}

export const LegacyProjectUnique = z.object({
    name: z.string(),
    columns: LegacyColumnName.array(),
    definition: z.string().optional(),
    origins: LegacyOrigin.array().optional()
}).strict()

export interface LegacyProjectIndex {
    name: string
    columns: LegacyColumnName[]
    definition?: string
    origins?: LegacyOrigin[]
}

export const LegacyProjectIndex = z.object({
    name: z.string(),
    columns: LegacyColumnName.array(),
    definition: z.string().optional(),
    origins: LegacyOrigin.array().optional()
}).strict()

export interface LegacyProjectCheck {
    name: string
    columns: LegacyColumnName[]
    predicate?: string
    origins?: LegacyOrigin[]
}

export const LegacyProjectCheck = z.object({
    name: z.string(),
    columns: LegacyColumnName.array(),
    predicate: z.string().optional(),
    origins: LegacyOrigin.array().optional()
}).strict()

// TODO: mutualise with LegacyTable in libs/models/src/legacy/legacyDatabase.ts:80
export interface LegacyProjectTable {
    schema: LegacySchemaName
    table: LegacyTableName
    view?: boolean
    definition?: string
    columns: LegacyProjectColumn[]
    primaryKey?: LegacyProjectPrimaryKey
    uniques?: LegacyProjectUnique[]
    indexes?: LegacyProjectIndex[]
    checks?: LegacyProjectCheck[]
    comment?: LegacyComment
    stats?: LegacyTableDbStats
    origins?: LegacyOrigin[]
}

export const LegacyProjectTable = z.object({
    schema: LegacySchemaName,
    table: LegacyTableName,
    view: z.boolean().optional(),
    definition: z.string().optional(),
    columns: LegacyProjectColumn.array(),
    primaryKey: LegacyProjectPrimaryKey.optional(),
    uniques: LegacyProjectUnique.array().optional(),
    indexes: LegacyProjectIndex.array().optional(),
    checks: LegacyProjectCheck.array().optional(),
    comment: LegacyComment.optional(),
    stats: LegacyTableDbStats.optional(),
    origins: LegacyOrigin.array().optional()
}).strict()

export interface LegacyProjectColumnRef {
    table: LegacyTableId
    column: LegacyColumnName
}

export const LegacyProjectColumnRef = z.object({
    table: LegacyTableId,
    column: LegacyColumnName
}).strict()

export interface LegacyProjectRelation {
    name: LegacyRelationName
    src: LegacyProjectColumnRef
    ref: LegacyProjectColumnRef
    origins?: LegacyOrigin[]
}

export const LegacyProjectRelation = z.object({
    name: LegacyRelationName,
    src: LegacyProjectColumnRef,
    ref: LegacyProjectColumnRef,
    origins: LegacyOrigin.array().optional()
}).strict()

export interface LegacyProjectType {
    schema: LegacySchemaName
    name: LegacyTypeName
    value: { enum: string[] } | { definition: string }
    origins?: LegacyOrigin[]
}

export const LegacyProjectType = z.object({
    schema: LegacySchemaName,
    name: LegacyTypeName,
    value: z.union([z.object({enum: z.string().array()}).strict(), z.object({definition: z.string()}).strict()]),
    origins: LegacyOrigin.array().optional()
}).strict()

export interface LegacySource {
    id: LegacySourceId
    name: LegacySourceName
    kind: LegacySourceKind
    content: LegacyLine[]
    tables: LegacyProjectTable[]
    relations: LegacyProjectRelation[]
    types?: LegacyProjectType[]
    enabled?: boolean
    fromSample?: string
    createdAt: Timestamp
    updatedAt: Timestamp
}

export const LegacySource = z.object({
    id: LegacySourceId,
    name: LegacySourceName,
    kind: LegacySourceKind,
    content: LegacyLine.array(),
    tables: LegacyProjectTable.array(),
    relations: LegacyProjectRelation.array(),
    types: LegacyProjectType.array().optional(),
    enabled: z.boolean().optional(),
    fromSample: z.string().optional(),
    createdAt: Timestamp,
    updatedAt: Timestamp
}).strict()

export interface LegacyCanvasProps {
    position: Position
    zoom: LegacyZoomLevel
}

export const LegacyCanvasProps = z.object({
    position: Position,
    zoom: LegacyZoomLevel
}).strict()

export interface LegacyTableProps {
    id: LegacyTableId
    position: Position
    size: Size
    color: Color
    columns: LegacyColumnName[]
    selected?: boolean
    collapsed?: boolean
    hiddenColumns?: boolean
}

export const LegacyTableProps = z.object({
    id: LegacyTableId,
    position: Position,
    size: Size,
    color: Color,
    columns: LegacyColumnName.array(),
    selected: z.boolean().optional(),
    collapsed: z.boolean().optional(),
    hiddenColumns: z.boolean().optional()
}).strict()

export type LegacyNotes = string
export const LegacyNotes = z.string()
export type LegacyTag = string
export const LegacyTag = z.string()

export interface LegacyColumnMeta {
    notes?: LegacyNotes
    tags?: LegacyTag[]
}

export const LegacyColumnMeta = z.object({
    notes: LegacyNotes.optional(),
    tags: LegacyTag.array().optional()
}).strict()

export interface LegacyTableMeta {
    notes?: LegacyNotes
    tags?: LegacyTag[]
    columns: { [column: LegacyColumnPathStr]: LegacyColumnMeta }
}

export const LegacyTableMeta = z.object({
    notes: LegacyNotes.optional(),
    tags: LegacyTag.array().optional(),
    columns: z.record(LegacyColumnPathStr, LegacyColumnMeta)
}).strict()

export interface LegacyMemo {
    id: LegacyMemoId
    content: string
    position: Position
    size: Size
    color?: Color
    selected?: boolean
}

export const LegacyMemo = z.object({
    id: LegacyMemoId,
    content: z.string(),
    position: Position,
    size: Size,
    color: Color.optional(),
    selected: z.boolean().optional()
}).strict()

export type LegacySqlQueryOrigin = {sql: string, origin: string, db: string}
export const LegacySqlQueryOrigin = z.object({sql: z.string(), origin: z.string(), db: z.string()}).strict()

export interface LegacyRowValue {
    column: LegacyColumnPathStr
    value: LegacyJsValue
}

export const LegacyRowValue = z.object({
    column: LegacyColumnPathStr,
    value: LegacyJsValue
}).strict()

export type LegacyRowPrimaryKey = LegacyRowValue[]
export const LegacyRowPrimaryKey = LegacyRowValue.array()

export interface LegacyTableRowColumn {
    path: LegacyColumnPathStr
    value: LegacyJsValue
    linkedBy?: Record<LegacyTableId, LegacyRowPrimaryKey[]> // legacy, keep it only for retro-compatibility
}

export const LegacyTableRowColumn = z.object({
    path: LegacyColumnPathStr,
    value: LegacyJsValue,
    linkedBy: z.record(LegacyTableId, LegacyRowPrimaryKey.array()).optional()
}).strict()

export interface LegacyTableRowStateSuccess {
    columns: LegacyTableRowColumn[]
    startedAt: Timestamp
    loadedAt: Timestamp
}

export const LegacyTableRowStateSuccess = z.object({
    columns: LegacyTableRowColumn.array(),
    startedAt: Timestamp,
    loadedAt: Timestamp
}).strict()

export interface LegacyTableRowStateFailure {
    query: LegacySqlQueryOrigin
    error: string
    startedAt: Timestamp
    failedAt: Timestamp
}

export const LegacyTableRowStateFailure = z.object({
    query: LegacySqlQueryOrigin,
    error: z.string(),
    startedAt: Timestamp,
    failedAt: Timestamp
}).strict()

export interface LegacyTableRowStateLoading {
    query: LegacySqlQueryOrigin
    startedAt: Timestamp
}

export const LegacyTableRowStateLoading = z.object({
    query: LegacySqlQueryOrigin,
    startedAt: Timestamp
}).strict()

export type LegacyTableRowState = LegacyTableRowStateSuccess | LegacyTableRowStateFailure | LegacyTableRowStateLoading
export const LegacyTableRowState = z.union([LegacyTableRowStateSuccess, LegacyTableRowStateFailure, LegacyTableRowStateLoading])

export interface LegacyTableRow {
    id: LegacyTableRowId
    position: Position
    size: Size
    source: LegacySourceId
    table: LegacyTableId
    primaryKey: LegacyRowPrimaryKey
    state: LegacyTableRowState
    hidden?: LegacyColumnPathStr[]
    showHiddenColumns?: boolean
    selected?: boolean
    collapsed?: boolean
}

export const LegacyTableRow = z.object({
    id: LegacyTableRowId,
    position: Position,
    size: Size,
    source: LegacySourceId,
    table: LegacyTableId,
    primaryKey: LegacyRowPrimaryKey,
    state: LegacyTableRowState,
    hidden: LegacyColumnPathStr.array().optional(),
    showHiddenColumns: z.boolean().optional(),
    selected: z.boolean().optional(),
    collapsed: z.boolean().optional()
}).strict()

export interface LegacyGroup {
    name: string
    tables: LegacyTableId[]
    color: Color
    collapsed?: boolean
}

export const LegacyGroup = z.object({
    name: z.string(),
    tables: LegacyTableId.array(),
    color: Color,
    collapsed: z.boolean().optional()
}).strict()

export interface LegacyLayout {
    canvas?: LegacyCanvasProps // legacy property, keep it for retro compatibility
    tables: LegacyTableProps[]
    tableRows?: LegacyTableRow[]
    groups?: LegacyGroup[]
    memos?: LegacyMemo[]
    createdAt: Timestamp
    updatedAt: Timestamp
}

export const LegacyLayout = z.object({
    canvas: LegacyCanvasProps.optional(),
    tables: LegacyTableProps.array(),
    tableRows: LegacyTableRow.array().optional(),
    groups: LegacyGroup.array().optional(),
    memos: LegacyMemo.array().optional(),
    createdAt: Timestamp,
    updatedAt: Timestamp
}).strict()

export type LegacyOrganizationId = Uuid
export const LegacyOrganizationId = Uuid
export type LegacyOrganizationSlug = Slug
export const LegacyOrganizationSlug = Slug
export type LegacyOrganizationName = string
export const LegacyOrganizationName = z.string()
export type LegacyPlanId = 'free' | 'solo' | 'team' | 'enterprise' | 'pro'
export const LegacyPlanId = z.enum(['free', 'solo', 'team', 'enterprise', 'pro'])

// MUST stay in sync with frontend/src/Models/Plan.elm & backend/lib/azimutt/organizations/organization_plan.ex
export interface LegacyPlan {
    id: LegacyPlanId
    name: string
    data_exploration: boolean
    colors: boolean
    aml: number | null
    schema_export: boolean
    ai: boolean
    analysis: string
    project_export: boolean
    projects: number | null
    project_dbs: number | null
    project_layouts: number | null
    layout_tables: number | null
    project_doc: number | null
    project_share: boolean
    streak: number
}

export const LegacyPlan = z.object({
    id: LegacyPlanId,
    name: z.string(),
    data_exploration: z.boolean(),
    colors: z.boolean(),
    aml: z.number().nullable(),
    schema_export: z.boolean(),
    ai: z.boolean(),
    analysis: z.string(),
    project_export: z.boolean(),
    projects: z.number().nullable(),
    project_dbs: z.number().nullable(),
    project_layouts: z.number().nullable(),
    layout_tables: z.number().nullable(),
    project_doc: z.number().nullable(),
    project_share: z.boolean(),
    streak: z.number(),
}).strict()

export const LegacyCleverCloudId = Uuid
export type LegacyCleverCloudId = Uuid
export type LegacyHerokuId = Uuid
export const LegacyHerokuId = Uuid

export const LegacyCleverCloudResource = z.object({id: LegacyCleverCloudId}).strict()
export type LegacyCleverCloudResource = { id: LegacyCleverCloudId }
export const LegacyHerokuResource = z.object({id: LegacyHerokuId}).strict()
export type LegacyHerokuResource = { id: LegacyHerokuId }

export interface LegacyOrganization {
    id: LegacyOrganizationId
    slug: LegacyOrganizationSlug
    name: LegacyOrganizationName
    plan: LegacyPlan
    logo: string
    description?: string
    clever_cloud?: LegacyCleverCloudResource
    heroku?: LegacyHerokuResource
}

export const LegacyOrganization = z.object({
    id: LegacyOrganizationId,
    slug: LegacyOrganizationSlug,
    name: LegacyOrganizationName,
    plan: LegacyPlan,
    logo: z.string().url(),
    description: z.string().optional(),
    clever_cloud: LegacyCleverCloudResource.optional(),
    heroku: LegacyHerokuResource.optional(),
}).strict()

export interface LegacySettings {
    findPath?: { maxPathLength?: number, ignoredTables?: string, ignoredColumns?: string }
    defaultSchema?: LegacySchemaName
    removedSchemas?: LegacySchemaName[]
    removeViews?: boolean
    removedTables?: string
    hiddenColumns?: { list?: string, max?: number, props?: boolean, relations?: boolean }
    columnOrder?: 'sql' | 'property' | 'name' | 'type'
    relationStyle?: 'Bezier' | 'Straight' | 'Steps'
    columnBasicTypes?: boolean
    collapseTableColumns?: boolean
    llm?: { key: OpenAIKey, model: OpenAIModel }
}

export const LegacySettings = z.object({
    findPath: z.object({
        maxPathLength: z.number().optional(),
        ignoredTables: z.string().optional(),
        ignoredColumns: z.string().optional()
    }).strict().optional(),
    defaultSchema: LegacySchemaName.optional(),
    removedSchemas: LegacySchemaName.array().optional(),
    removeViews: z.boolean().optional(),
    removedTables: z.string().optional(),
    hiddenColumns: z.object({
        list: z.string().optional(),
        max: z.number().optional(),
        props: z.boolean().optional(),
        relations: z.boolean().optional()
    }).strict().optional(),
    columnOrder: z.enum(['sql', 'property', 'name', 'type']).optional(),
    relationStyle: z.enum(['Bezier', 'Straight', 'Steps']).optional(),
    columnBasicTypes: z.boolean().optional(),
    collapseTableColumns: z.boolean().optional(),
    llm: z.object({
        key: OpenAIKey,
        model: OpenAIModel,
    }).strict().optional(),
}).strict()

export type LegacyProjectStorage = 'local' | 'remote'
export const LegacyProjectStorage = z.enum(['local', 'remote'])

export type LegacyProjectVisibility = 'none' | 'read' | 'write'
export const LegacyProjectVisibility = z.enum(['none', 'read', 'write'])

export type LegacyProjectVersion = 1 | 2
export const LegacyProjectVersion = z.union([z.literal(1), z.literal(2)])

export interface LegacyProject {
    organization?: LegacyOrganization
    id: LegacyProjectId
    slug: LegacyProjectSlug
    name: LegacyProjectName
    description?: string
    sources: LegacySource[]
    ignoredRelations?: { [table: string]: LegacyColumnPathStr[] }
    notes?: { [ref: string]: string } // legacy property, keep it for retro compatibility
    metadata?: { [table: LegacyTableId]: LegacyTableMeta }
    usedLayout?: LegacyLayoutName // legacy property, keep it for retro compatibility
    layouts: { [name: LegacyLayoutName]: LegacyLayout }
    tableRowsSeq?: number
    settings?: LegacySettings
    storage: LegacyProjectStorage
    visibility: LegacyProjectVisibility
    createdAt: Timestamp
    updatedAt: Timestamp
    version: LegacyProjectVersion
}

export const LegacyProject = z.object({
    organization: LegacyOrganization.optional(),
    id: LegacyProjectId,
    slug: LegacyProjectSlug,
    name: LegacyProjectName,
    description: z.string().optional(),
    sources: LegacySource.array(),
    ignoredRelations: z.record(LegacyColumnPathStr.array()).optional(),
    notes: z.record(z.string()).optional(),
    metadata: z.record(LegacyTableId, LegacyTableMeta).optional(),
    usedLayout: LegacyLayoutName.optional(),
    layouts: z.record(LegacyLayoutName, LegacyLayout),
    tableRowsSeq: z.number().optional(),
    settings: LegacySettings.optional(),
    storage: LegacyProjectStorage,
    visibility: LegacyProjectVisibility,
    createdAt: Timestamp,
    updatedAt: Timestamp,
    version: LegacyProjectVersion
}).strict().describe('LegacyProject')

export type LegacyProjectJson = Omit<LegacyProject, 'organization' | 'id' | 'storage' | 'visibility' | 'createdAt' | 'updatedAt'> & { _type: 'json' }
export const LegacyProjectJson = LegacyProject.omit({organization: true, id: true, storage: true, visibility: true, createdAt: true, updatedAt: true}).extend({_type: z.literal('json')}).strict().describe('LegacyProjectJson')

export interface LegacyProjectStats {
    nbSources: number
    nbTables: number
    nbColumns: number
    nbRelations: number
    nbTypes: number
    nbComments: number
    nbLayouts: number
    nbNotes: number
    nbMemos: number
}

export const LegacyProjectStats = z.object({
    nbSources: z.number(),
    nbTables: z.number(),
    nbColumns: z.number(),
    nbRelations: z.number(),
    nbTypes: z.number(),
    nbComments: z.number(),
    nbLayouts: z.number(),
    nbNotes: z.number(),
    nbMemos: z.number()
}).strict().describe('LegacyProjectStats')

export interface LegacyProjectInfoLocal extends LegacyProjectStats {
    organization?: LegacyOrganization
    id: LegacyProjectId
    slug: LegacyProjectSlug
    name: LegacyProjectName
    description?: string
    storage: 'local'
    visibility: LegacyProjectVisibility
    encodingVersion: LegacyProjectVersion
    createdAt: Timestamp
    updatedAt: Timestamp
}

export const LegacyProjectInfoLocal = LegacyProjectStats.extend({
    organization: LegacyOrganization.optional(),
    id: LegacyProjectId,
    slug: LegacyProjectSlug,
    name: LegacyProjectName,
    description: z.string().optional(),
    storage: z.literal(LegacyProjectStorage.enum.local),
    visibility: LegacyProjectVisibility,
    encodingVersion: LegacyProjectVersion,
    createdAt: Timestamp,
    updatedAt: Timestamp
}).strict()

export type LegacyProjectInfoRemote = Omit<LegacyProjectInfoLocal, 'storage'> & { storage: 'remote' }
export const LegacyProjectInfoRemote = LegacyProjectInfoLocal.omit({storage: true}).extend({storage: z.literal(LegacyProjectStorage.enum.remote)}).strict()
export type LegacyProjectInfoRemoteWithContent = LegacyProjectInfoRemote & { content: LegacyProjectJson }
export type LegacyProjectInfo = LegacyProjectInfoLocal | LegacyProjectInfoRemote
export const LegacyProjectInfo = z.discriminatedUnion('storage', [LegacyProjectInfoLocal, LegacyProjectInfoRemote])
export type LegacyProjectInfoWithContent = LegacyProjectInfoLocal | LegacyProjectInfoRemoteWithContent


export function legacyIsLocal(p: LegacyProjectInfo): p is LegacyProjectInfoLocal {
    return p.storage === LegacyProjectStorage.enum.local
}

export function legacyIsRemote(p: LegacyProjectInfo): p is LegacyProjectInfoRemote {
    return p.storage === LegacyProjectStorage.enum.remote
}

export function legacyParseTableId(id: LegacyTableId): {schema: LegacySchemaName, table: LegacyTableName} {
    const [schema, table] = id.split(".")
    return table === undefined ? {schema: "", table: schema} : {schema, table}
}

export function legacyBuildProjectDraft(id: LegacyProjectId, {_type, ...p}: LegacyProjectJson): LegacyProject {
    return zodParse(LegacyProject)({
        ...p,
        id,
        slug: id,
        storage: LegacyProjectStorage.enum.local,
        visibility: LegacyProjectVisibility.enum.none,
        createdAt: Date.now(),
        updatedAt: Date.now()
    }).getOrThrow()
}

export function legacyBuildProjectLocal(info: LegacyProjectInfoLocal, {_type, ...p}: LegacyProjectJson): LegacyProject {
    return zodParse(LegacyProject)({
        ...p,
        organization: info.organization,
        id: info.id,
        storage: LegacyProjectStorage.enum.local,
        visibility: LegacyProjectVisibility.enum.none,
        createdAt: info.createdAt,
        updatedAt: info.updatedAt
    }).getOrThrow()
}

export function legacyBuildProjectRemote(info: LegacyProjectInfoRemote, {_type, ...p}: LegacyProjectJson): LegacyProject {
    return zodParse(LegacyProject)({
        ...p,
        organization: info.organization,
        id: info.id,
        slug: info.slug,
        storage: LegacyProjectStorage.enum.remote,
        visibility: info.visibility,
        createdAt: info.createdAt,
        updatedAt: info.updatedAt
    }).getOrThrow()
}

export function legacyBuildProjectJson({organization, id, storage, visibility, createdAt, updatedAt, ...p}: LegacyProject): LegacyProjectJson {
    return zodParse(LegacyProjectJson)({...p, _type: 'json'}).getOrThrow()
}

export function legacyComputeStats(p: LegacyProjectJson): LegacyProjectStats {
    // should be the same as `tables`, `relations` and `types` in src/Models/Project.elm
    const tables = groupBy(p.sources.flatMap(s => s.tables), t => `${t.schema}.${t.table}`)
    const relations = groupBy(p.sources.flatMap(s => s.relations), r => `${r.src.table}.${r.src.column}->${r.ref.table}.${r.ref.column}`)
    const types = groupBy(p.sources.flatMap(s => s.types || []), t => `${t.schema}.${t.name}`)

    return zodParse(LegacyProjectStats)({
        nbSources: p.sources.length,
        nbTables: Object.keys(tables).length,
        nbColumns: Object.values(tables).map(same => Math.max(...same.map(t => t.columns.length))).reduce((acc, cols) => acc + cols, 0),
        nbRelations: Object.keys(relations).length,
        nbTypes: Object.keys(types).length,
        nbComments: p.sources.flatMap(s => s.tables.flatMap(t => [t.comment].concat(t.columns.map(c => c.comment)).filter(c => !!c))).length,
        nbLayouts: Object.keys(p.layouts).length,
        nbNotes: Object.keys(p.notes || {}).length,
        nbMemos: Object.values(p.layouts).flatMap(l => l.memos || []).length,
    }).getOrThrow()
}

export function sourceToDatabase(s: LegacySource): Database {
    return removeEmpty({
        entities: s.tables.map(projectTableToEntity),
        relations: s.relations.map(relationFromLegacy),
        types: s.types?.map(projectTypeFromLegacy),
        stats: removeUndefined({
            name: s.name,
            kind: s.kind.kind === 'DatabaseConnection' ? (s.kind.engine ? s.kind.engine : s.kind.url ? parseDatabaseUrl(s.kind.url).kind : undefined) : undefined
        })
    })
}

export function projectTableToEntity(t: LegacyProjectTable): Entity {
    return removeUndefined({
        database: undefined,
        catalog: undefined,
        schema: t.schema || undefined,
        name: t.table,
        kind: t.view ? 'view' as const : undefined,
        def: t.definition,
        attrs: t.columns.map(projectColumnToAttribute),
        pk: t.primaryKey ? primaryKeyFromLegacy(t.primaryKey) : undefined,
        indexes: (t.uniques ||  []).map(uniqueFromLegacy).concat((t.indexes || []).map(indexFromLegacy)),
        checks: t.checks?.map(checkFromLegacy),
        doc: t.comment?.text,
        stats: t.stats ? tableDbStatsFromLegacy(t.stats) : undefined,
        extra: undefined,
    })
}

export function projectColumnToAttribute(c: LegacyProjectColumn): Attribute {
    return removeEmpty({
        name: c.name,
        type: c.type,
        null: c.nullable,
        gen: undefined,
        default: c.default,
        attrs: c.columns?.map(projectColumnToAttribute),
        doc: c.comment?.text,
        stats: removeUndefined({
            nulls: c.stats?.nulls,
            bytesAvg: c.stats?.bytesAvg,
            cardinality: c.stats?.cardinality,
            commonValues: c.stats?.commonValues?.map(v => ({value: columnValueFromLegacy(v.value), freq: v.freq})),
            distinctValues: c.values?.map(columnValueFromLegacy),
            histogram: c.stats?.histogram?.map(columnValueFromLegacy),
            min: undefined,
            max: undefined,
        })
    })
}

export function projectTypeFromLegacy(t: LegacyProjectType): Type {
    if ('enum' in t.value) {
        return removeUndefined({schema: t.schema || undefined, name: t.name, values: t.value.enum || undefined})
    } else {
        return removeUndefined({schema: t.schema || undefined, name: t.name, definition: t.value.definition})
    }
}
