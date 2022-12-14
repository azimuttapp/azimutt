import {Color, Position, Size, Slug, Timestamp} from "./basics";
import {Uuid} from "./uuid";
import {Organization} from "./organization";
import * as array from "../utils/array";
import * as object from "../utils/object";
import {z} from "zod";
import * as Zod from "../utils/zod";

export type ProjectId = Uuid
export const ProjectId = Uuid
export type ProjectSlug = Slug
export const ProjectSlug = Slug
export type ProjectName = string
export const ProjectName = z.string()
export type SourceId = Uuid
export const SourceId = Uuid
export type SourceName = string
export const SourceName = z.string()
export type TableId = string
export const TableId = z.string()
export type SchemaName = string
export const SchemaName = z.string()
export type TableName = string
export const TableName = z.string()
export type ColumnId = string
export const ColumnId = z.string()
export type ColumnName = string
export const ColumnName = z.string()
export type ColumnType = string
export const ColumnType = z.string()
export type Line = string
export const Line = z.string()
export type LineIndex = number
export const LineIndex = z.number()
export type RelationName = string
export const RelationName = z.string()
export type TypeName = string
export const TypeName = z.string()
export type LayoutName = string
export const LayoutName = z.string()
export type ZoomLevel = number
export const ZoomLevel = z.number()

export interface DatabaseConnection {
    kind: 'DatabaseConnection',
    url: string
}

export const DatabaseConnection = z.object({
    kind: z.literal('DatabaseConnection'),
    url: z.string()
}).strict()

export interface SqlLocalFile {
    kind: 'SqlLocalFile',
    name: string,
    size: number,
    modified: Timestamp
}

export const SqlLocalFile = z.object({
    kind: z.literal('SqlLocalFile'),
    name: z.string(),
    size: z.number(),
    modified: Timestamp
}).strict()

export interface SqlRemoteFile {
    kind: 'SqlRemoteFile',
    url: string,
    size: number
}

export const SqlRemoteFile = z.object({
    kind: z.literal('SqlRemoteFile'),
    url: z.string(),
    size: z.number()
}).strict()

export interface JsonLocalFile {
    kind: 'JsonLocalFile',
    name: string,
    size: number,
    modified: Timestamp
}

export const JsonLocalFile = z.object({
    kind: z.literal('JsonLocalFile'),
    name: z.string(),
    size: z.number(),
    modified: Timestamp
}).strict()

export interface JsonRemoteFile {
    kind: 'JsonRemoteFile',
    url: string,
    size: number
}

export const JsonRemoteFile = z.object({
    kind: z.literal('JsonRemoteFile'),
    url: z.string(),
    size: z.number()
}).strict()

export interface AmlEditor {
    kind: 'AmlEditor'
}

export const AmlEditor = z.object({
    kind: z.literal('AmlEditor')
}).strict()

export type SourceKind = DatabaseConnection | SqlLocalFile | SqlRemoteFile | JsonLocalFile | JsonRemoteFile | AmlEditor
export const SourceKind = z.discriminatedUnion('kind', [DatabaseConnection, SqlLocalFile, SqlRemoteFile, JsonLocalFile, JsonRemoteFile, AmlEditor])

export type SourceOrigin = 'import-project' | 'sql-source' | 'json-source'
export const SourceOrigin = z.enum(['import-project', 'sql-source', 'json-source'])

export interface Origin {
    id: SourceId
    lines: LineIndex[]
}

export const Origin = z.object({
    id: SourceId,
    lines: LineIndex.array()
}).strict()

export interface Comment {
    text: string
    origins: Origin[]
}

export const Comment = z.object({
    text: z.string(),
    origins: Origin.array()
}).strict()

export interface Column {
    name: ColumnName
    type: ColumnType
    nullable?: boolean
    default?: string
    comment?: Comment
    origins: Origin[]
}

export const Column = z.object({
    name: ColumnName,
    type: ColumnType,
    nullable: z.boolean().optional(),
    default: z.string().optional(),
    comment: Comment.optional(),
    origins: Origin.array()
}).strict()

export interface PrimaryKey {
    name?: string
    columns: ColumnName[]
    origins: Origin[]
}

export const PrimaryKey = z.object({
    name: z.string().optional(),
    columns: ColumnName.array(),
    origins: Origin.array()
}).strict()

export interface Unique {
    name: string
    columns: ColumnName[]
    definition?: string
    origins: Origin[]
}

export const Unique = z.object({
    name: z.string(),
    columns: ColumnName.array(),
    definition: z.string().optional(),
    origins: Origin.array()
}).strict()

export interface Index {
    name: string
    columns: ColumnName[]
    definition?: string
    origins: Origin[]
}

export const Index = z.object({
    name: z.string(),
    columns: ColumnName.array(),
    definition: z.string().optional(),
    origins: Origin.array()
}).strict()

export interface Check {
    name: string
    columns: ColumnName[]
    predicate?: string
    origins: Origin[]
}

export const Check = z.object({
    name: z.string(),
    columns: ColumnName.array(),
    predicate: z.string().optional(),
    origins: Origin.array()
}).strict()

export interface Table {
    schema: SchemaName
    table: TableName
    view?: boolean
    columns: Column[]
    primaryKey?: PrimaryKey
    uniques?: Unique[]
    indexes?: Index[]
    checks?: Check[]
    comment?: Comment
    origins: Origin[]
}

export const Table = z.object({
    schema: SchemaName,
    table: TableName,
    view: z.boolean().optional(),
    columns: Column.array(),
    primaryKey: PrimaryKey.optional(),
    uniques: Unique.array().optional(),
    indexes: Index.array().optional(),
    checks: Check.array().optional(),
    comment: Comment.optional(),
    origins: Origin.array()
}).strict()

export interface ColumnRef {
    table: TableId
    column: ColumnName
}

export const ColumnRef = z.object({
    table: TableId,
    column: ColumnName
}).strict()

export interface Relation {
    name: RelationName
    src: ColumnRef
    ref: ColumnRef
    origins: Origin[]
}

export const Relation = z.object({
    name: RelationName,
    src: ColumnRef,
    ref: ColumnRef,
    origins: Origin.array()
}).strict()

export interface Type {
    schema: SchemaName
    name: TypeName
    value: { enum: string[] } | { definition: string }
    origins: Origin[]
}

export const Type = z.object({
    schema: SchemaName,
    name: TypeName,
    value: z.union([z.object({enum: z.string().array()}).strict(), z.object({definition: z.string()}).strict()]),
    origins: Origin.array()
}).strict()

export interface Source {
    id: SourceId
    name: SourceName
    kind: SourceKind
    content: Line[]
    tables: Table[]
    relations: Relation[]
    types?: Type[]
    enabled?: boolean
    fromSample?: string
    createdAt: Timestamp
    updatedAt: Timestamp
}

export const Source = z.object({
    id: SourceId,
    name: SourceName,
    kind: SourceKind,
    content: Line.array(),
    tables: Table.array(),
    relations: Relation.array(),
    types: Type.array().optional(),
    enabled: z.boolean().optional(),
    fromSample: z.string().optional(),
    createdAt: Timestamp,
    updatedAt: Timestamp
}).strict()

export interface CanvasProps {
    position: Position
    zoom: ZoomLevel
}

export const CanvasProps = z.object({
    position: Position,
    zoom: ZoomLevel
}).strict()

export interface TableProps {
    id: TableId
    position: Position
    size: Size
    color: Color
    columns: ColumnName[]
    selected?: boolean
    collapsed?: boolean
    hiddenColumns?: boolean
}

export const TableProps = z.object({
    id: TableId,
    position: Position,
    size: Size,
    color: Color,
    columns: ColumnName.array(),
    selected: z.boolean().optional(),
    collapsed: z.boolean().optional(),
    hiddenColumns: z.boolean().optional()
}).strict()

export interface Layout {
    canvas: CanvasProps
    tables: TableProps[]
    createdAt: Timestamp
    updatedAt: Timestamp
}

export const Layout = z.object({
    canvas: CanvasProps,
    tables: TableProps.array(),
    createdAt: Timestamp,
    updatedAt: Timestamp
}).strict()

export interface Settings {
    findPath?: { maxPathLength?: number, ignoredTables?: string, ignoredColumns?: string }
    defaultSchema?: SchemaName
    removedSchemas?: SchemaName[]
    removeViews?: boolean
    removedTables?: string
    hiddenColumns?: { list?: string, max?: number, props?: boolean, relations?: boolean }
    columnOrder?: 'sql' | 'property' | 'name' | 'type'
    relationStyle?: 'Bezier' | 'Straight' | 'Steps'
    columnBasicTypes?: boolean
    collapseTableColumns?: boolean
}

export const Settings = z.object({
    findPath: z.object({
        maxPathLength: z.number().optional(),
        ignoredTables: z.string().optional(),
        ignoredColumns: z.string().optional()
    }).strict().optional(),
    defaultSchema: SchemaName.optional(),
    removedSchemas: SchemaName.array().optional(),
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
    collapseTableColumns: z.boolean().optional()
}).strict()

export type ProjectStorage = 'local' | 'remote'
export const ProjectStorage = z.enum(['local', 'remote'])

export type ProjectVisibility = 'none' | 'read' | 'write'
export const ProjectVisibility = z.enum(['none', 'read', 'write'])

export type ProjectVersion = 1 | 2
export const ProjectVersion = z.union([z.literal(1), z.literal(2)])

export interface Project {
    organization?: Organization
    id: ProjectId
    slug: ProjectSlug
    name: ProjectName
    description?: string
    sources: Source[]
    notes?: { [ref: string]: string }
    usedLayout: LayoutName
    layouts: { [name: LayoutName]: Layout }
    settings?: Settings
    storage: ProjectStorage
    visibility: ProjectVisibility
    createdAt: Timestamp
    updatedAt: Timestamp
    version: ProjectVersion
}

export const Project = z.object({
    organization: Organization.optional(),
    id: ProjectId,
    slug: ProjectSlug,
    name: ProjectName,
    description: z.string().optional(),
    sources: Source.array(),
    notes: z.record(z.string()).optional(),
    usedLayout: LayoutName,
    layouts: z.record(LayoutName, Layout),
    settings: Settings.optional(),
    storage: ProjectStorage,
    visibility: ProjectVisibility,
    createdAt: Timestamp,
    updatedAt: Timestamp,
    version: ProjectVersion
}).strict()

export type ProjectJson = Omit<Project, 'organization' | 'id' | 'storage' | 'visibility' | 'createdAt' | 'updatedAt'> & { _type: 'json' }
export const ProjectJson = Project.omit({organization: true, id: true, storage: true, visibility: true, createdAt: true, updatedAt: true}).extend({_type: z.literal('json')}).strict()
export type ProjectJsonLegacy = Omit<Project, 'organization' | 'slug' | 'description' | 'storage' | 'visibility'>
export const ProjectJsonLegacy = Project.omit({organization: true, slug: true, description: true, storage: true, visibility: true}).strict()
export type ProjectStored = ProjectJson | ProjectJsonLegacy
export const ProjectStored = z.union([ProjectJson, ProjectJsonLegacy])
export type ProjectStoredWithId = [ProjectId, ProjectStored]
export const ProjectStoredWithId = z.tuple([ProjectId, ProjectStored])

export interface ProjectStats {
    nbSources: number
    nbTables: number
    nbColumns: number
    nbRelations: number
    nbTypes: number
    nbComments: number
    nbNotes: number
    nbLayouts: number
}

export const ProjectStats = z.object({
    nbSources: z.number(),
    nbTables: z.number(),
    nbColumns: z.number(),
    nbRelations: z.number(),
    nbTypes: z.number(),
    nbComments: z.number(),
    nbNotes: z.number(),
    nbLayouts: z.number()
}).strict()

export interface ProjectInfoLocal extends ProjectStats {
    organization?: Organization
    id: ProjectId
    slug: ProjectSlug
    name: ProjectName
    description?: string
    storage: 'local'
    encodingVersion: ProjectVersion
    createdAt: Timestamp
    updatedAt: Timestamp
}

export const ProjectInfoLocal = ProjectStats.extend({
    organization: Organization.optional(),
    id: ProjectId,
    slug: ProjectSlug,
    name: ProjectName,
    description: z.string().optional(),
    storage: z.literal(ProjectStorage.enum.local),
    encodingVersion: ProjectVersion,
    createdAt: Timestamp,
    updatedAt: Timestamp
}).strict()

export type ProjectInfoRemote = Omit<ProjectInfoLocal, 'storage'> & { storage: 'remote', visibility: ProjectVisibility }
export const ProjectInfoRemote = ProjectInfoLocal.omit({storage: true}).extend({storage: z.literal(ProjectStorage.enum.remote), visibility: ProjectVisibility}).strict()
export type ProjectInfoRemoteWithContent = ProjectInfoRemote & { content: ProjectJson }
export type ProjectInfo = ProjectInfoLocal | ProjectInfoRemote
export const ProjectInfo = z.discriminatedUnion('storage', [ProjectInfoLocal, ProjectInfoRemote])
export type ProjectInfoWithContent = ProjectInfoLocal | ProjectInfoRemoteWithContent
export type ProjectInfoLocalLegacy = Omit<ProjectInfoLocal, 'organization'> & { visibility: ProjectVisibility }
export const ProjectInfoLocalLegacy = ProjectInfoLocal.omit({organization: true}).extend({visibility: ProjectVisibility}).strict()


export function isLocal(p: ProjectInfo): p is ProjectInfoLocal {
    return p.storage === ProjectStorage.enum.local
}

export function isRemote(p: ProjectInfo): p is ProjectInfoRemote {
    return p.storage === ProjectStorage.enum.remote
}

export function isLegacy(p: ProjectStored): p is ProjectJsonLegacy {
    return 'createdAt' in p
}

// required read transformations to satisfy Zod validations
export function migrateLegacyProject(p: any | undefined): any {
    if (!p) return p
    if (p.createdAt) { // if legacy, remove storage and transform sources & layouts
        const {storage, layout, ...res} = p
        const layouts = Object.assign(layout ? {'initial layout': layout} : {}, res.layouts)
        const usedLayout = layout ? 'initial layout' : res.usedLayout || Object.keys(res.layouts)[0]
        return {
            ...res,
            sources: res.sources.map(migrateLegacySource),
            layouts: object.mapValues(layouts, migrateLegacyLayout),
            usedLayout
        }
    } else { // if not legacy, remove id
        const {id, ...res} = p
        return res
    }
}

function migrateLegacySource(s: any) {
    const kind = s.kind.kind === 'LocalFile' ? 'SqlLocalFile' :
        s.kind.kind === 'RemoteFile' ? 'SqlRemoteFile' :
            s.kind.kind === 'UserDefined' ? 'AmlEditor' : s.kind.kind

    return {
        ...s,
        kind: {...s.kind, kind},
        tables: s.tables.map((t: any) => ({
            ...t,
            columns: t.columns.map((c: any) => ({...c, origins: c.origins || []})),
            primaryKey: t.primaryKey ? {...t.primaryKey, origins: t.primaryKey.origins || []} : t.primaryKey,
            checks: t.checks?.map((c: any) => ({...c, columns: c.columns || []})),
            origins: t.origins || []
        })),
        relations: s.relations?.map((r: any) => ({
            ...r,
            origins: r.origins || []
        }))
    }
}

function migrateLegacyLayout(l: any) {
    return {
        ...l,
        tables: l.tables.map((t: any) => ({
            ...t,
            size: t.size || {width: 0, height: 0},
            columns: t.columns || []
        }))
    }
}

export function buildProjectLegacy(id: ProjectId, p: ProjectJsonLegacy): Project {
    return Zod.validate({
        ...p,
        id,
        slug: id,
        storage: ProjectStorage.enum.local,
        visibility: ProjectVisibility.enum.none
    }, Project, 'Project')
}

export function buildProjectDraft(id: ProjectId, {_type, ...p}: ProjectJson): Project {
    return Zod.validate({
        ...p,
        id,
        slug: id,
        storage: ProjectStorage.enum.local,
        visibility: ProjectVisibility.enum.none,
        createdAt: Date.now(),
        updatedAt: Date.now()
    }, Project, 'Project')
}

export function buildProjectLocal(info: ProjectInfoLocal, {_type, ...p}: ProjectJson): Project {
    return Zod.validate({
        ...p,
        organization: info.organization,
        id: info.id,
        storage: ProjectStorage.enum.local,
        visibility: ProjectVisibility.enum.none,
        createdAt: info.createdAt,
        updatedAt: info.updatedAt
    }, Project, 'Project')
}

export function buildProjectRemote(info: ProjectInfoRemote, {_type, ...p}: ProjectJson): Project {
    return Zod.validate({
        ...p,
        organization: info.organization,
        id: info.id,
        slug: info.slug,
        storage: ProjectStorage.enum.remote,
        visibility: info.visibility,
        createdAt: info.createdAt,
        updatedAt: info.updatedAt
    }, Project, 'Project')
}

export function buildProjectJson({organization, id, storage, visibility, createdAt, updatedAt, ...p}: Project): ProjectJson {
    return Zod.validate({...p, _type: 'json'}, ProjectJson, 'ProjectJson')
}

export function computeStats(p: ProjectStored): ProjectStats {
    // should be the same as `fromProject` in src/Models/ProjectInfo.elm
    const tables = array.groupBy(p.sources.flatMap(s => s.tables), t => `${t.schema}.${t.table}`)
    const types = array.groupBy(p.sources.flatMap(s => s.types || []), t => `${t.schema}.${t.name}`)

    return Zod.validate({
        nbSources: p.sources.length,
        nbTables: Object.keys(tables).length,
        nbColumns: Object.values(tables).map(same => Math.max(...same.map(t => t.columns.length))).reduce((acc, cols) => acc + cols, 0),
        nbRelations: p.sources.reduce((acc, src) => acc + src.relations.length, 0),
        nbTypes: Object.keys(types).length,
        nbComments: p.sources.flatMap(s => s.tables.flatMap(t => [t.comment].concat(t.columns.map(c => c.comment)).filter(c => !!c))).length,
        nbNotes: Object.keys(p.notes || {}).length,
        nbLayouts: Object.keys(p.layouts).length
    }, ProjectStats, 'ProjectStats')
}
