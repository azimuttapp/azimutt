import {z} from "zod";
import {groupBy} from "@azimutt/utils";
import {ColumnName, ColumnType, JsValue, SchemaName, TableId, TableName} from "@azimutt/database-types";
import {Color, Notes, Position, Size, Slug, Tag, Timestamp} from "./basics";
import {Uuid} from "./uuid";
import {Organization} from "./organization";
import * as Zod from "../utils/zod";

// MUST stay in sync with backend/lib/azimutt_web/utils/project_schema.ex

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
export type ColumnPathStr = string
export const ColumnPathStr = z.string()
export type Line = string
export const Line = z.string()
export type LineIndex = number
export const LineIndex = z.number()
export type RelationName = string
export const RelationName = z.string()
export type TypeName = string
export const TypeName = z.string()
export type TableRowId = number
export const TableRowId = z.number()
export type MemoId = number
export const MemoId = z.number()
export type LayoutName = string
export const LayoutName = z.string()
export type ZoomLevel = number
export const ZoomLevel = z.number()
export type ProjectTokenId = Uuid
export const ProjectTokenId = Uuid

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

export interface PrismaLocalFile {
    kind: 'PrismaLocalFile',
    name: string,
    size: number,
    modified: Timestamp
}

export const PrismaLocalFile = z.object({
    kind: z.literal('PrismaLocalFile'),
    name: z.string(),
    size: z.number(),
    modified: Timestamp
}).strict()

export interface PrismaRemoteFile {
    kind: 'PrismaRemoteFile',
    url: string,
    size: number
}

export const PrismaRemoteFile = z.object({
    kind: z.literal('PrismaRemoteFile'),
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

export type SourceKind = DatabaseConnection | SqlLocalFile | SqlRemoteFile | PrismaLocalFile | PrismaRemoteFile | JsonLocalFile | JsonRemoteFile | AmlEditor
export const SourceKind = z.discriminatedUnion('kind', [DatabaseConnection, SqlLocalFile, SqlRemoteFile, PrismaLocalFile, PrismaRemoteFile, JsonLocalFile, JsonRemoteFile, AmlEditor])

export type SourceOrigin = 'import-project' | 'sql-source' | 'prisma-source' | 'json-source'
export const SourceOrigin = z.enum(['import-project', 'sql-source', 'prisma-source', 'json-source'])

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
    origins?: Origin[]
}

export const Comment = z.object({
    text: z.string(),
    origins: Origin.array().optional()
}).strict()

export interface Column {
    name: ColumnName
    type: ColumnType
    nullable?: boolean
    default?: string
    comment?: Comment
    values?: string[]
    columns?: Column[]
    origins?: Origin[]
}

export const Column: z.ZodType<Column> = z.object({
    name: ColumnName,
    type: ColumnType,
    nullable: z.boolean().optional(),
    default: z.string().optional(),
    comment: Comment.optional(),
    values: z.string().array().optional(),
    columns: z.lazy(() => Column.array().optional()),
    origins: Origin.array().optional()
}).strict()

export interface PrimaryKey {
    name?: string
    columns: ColumnName[]
    origins?: Origin[]
}

export const PrimaryKey = z.object({
    name: z.string().optional(),
    columns: ColumnName.array(),
    origins: Origin.array().optional()
}).strict()

export interface Unique {
    name: string
    columns: ColumnName[]
    definition?: string
    origins?: Origin[]
}

export const Unique = z.object({
    name: z.string(),
    columns: ColumnName.array(),
    definition: z.string().optional(),
    origins: Origin.array().optional()
}).strict()

export interface Index {
    name: string
    columns: ColumnName[]
    definition?: string
    origins?: Origin[]
}

export const Index = z.object({
    name: z.string(),
    columns: ColumnName.array(),
    definition: z.string().optional(),
    origins: Origin.array().optional()
}).strict()

export interface Check {
    name: string
    columns: ColumnName[]
    predicate?: string
    origins?: Origin[]
}

export const Check = z.object({
    name: z.string(),
    columns: ColumnName.array(),
    predicate: z.string().optional(),
    origins: Origin.array().optional()
}).strict()

// TODO: mutualise with AzimuttTable in libs/database-types/src/schema.ts:77
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
    origins?: Origin[]
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
    origins: Origin.array().optional()
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
    origins?: Origin[]
}

export const Relation = z.object({
    name: RelationName,
    src: ColumnRef,
    ref: ColumnRef,
    origins: Origin.array().optional()
}).strict()

export interface Type {
    schema: SchemaName
    name: TypeName
    value: { enum: string[] } | { definition: string }
    origins?: Origin[]
}

export const Type = z.object({
    schema: SchemaName,
    name: TypeName,
    value: z.union([z.object({enum: z.string().array()}).strict(), z.object({definition: z.string()}).strict()]),
    origins: Origin.array().optional()
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

export interface ColumnMeta {
    notes?: Notes
    tags?: Tag[]
}

export const ColumnMeta = z.object({
    notes: Notes.optional(),
    tags: Tag.array().optional()
}).strict()

export interface TableMeta {
    notes?: Notes
    tags?: Tag[]
    columns: { [column: ColumnPathStr]: ColumnMeta }
}

export const TableMeta = z.object({
    notes: Notes.optional(),
    tags: Tag.array().optional(),
    columns: z.record(ColumnPathStr, ColumnMeta)
}).strict()

export interface Memo {
    id: MemoId
    content: string
    position: Position
    size: Size
    color?: Color
    selected?: boolean
}

export const Memo = z.object({
    id: MemoId,
    content: z.string(),
    position: Position,
    size: Size,
    color: Color.optional(),
    selected: z.boolean().optional()
}).strict()

export type SqlQueryOrigin = {sql: string, origin: string, db: string}
export const SqlQueryOrigin = z.object({sql: z.string(), origin: z.string(), db: z.string()}).strict()

export interface RowValue {
    column: ColumnPathStr
    value: JsValue
}

export const RowValue = z.object({
    column: ColumnPathStr,
    value: JsValue
}).strict()

export type RowPrimaryKey = RowValue[]
export const RowPrimaryKey = RowValue.array()

export interface TableRowColumn {
    path: ColumnPathStr
    value: JsValue
    linkedBy?: Record<TableId, RowPrimaryKey[]>
}

export const TableRowColumn = z.object({
    path: ColumnPathStr,
    value: JsValue,
    linkedBy: z.record(TableId, RowPrimaryKey.array()).optional()
}).strict()

export interface TableRowStateSuccess {
    columns: TableRowColumn[]
    startedAt: Timestamp
    loadedAt: Timestamp
}

export const TableRowStateSuccess = z.object({
    columns: TableRowColumn.array(),
    startedAt: Timestamp,
    loadedAt: Timestamp
}).strict()

export interface TableRowStateFailure {
    query: SqlQueryOrigin
    error: string
    startedAt: Timestamp
    failedAt: Timestamp
}

export const TableRowStateFailure = z.object({
    query: SqlQueryOrigin,
    error: z.string(),
    startedAt: Timestamp,
    failedAt: Timestamp
}).strict()

export interface TableRowStateLoading {
    query: SqlQueryOrigin
    startedAt: Timestamp
}

export const TableRowStateLoading = z.object({
    query: SqlQueryOrigin,
    startedAt: Timestamp
}).strict()

export type TableRowState = TableRowStateSuccess | TableRowStateFailure | TableRowStateLoading
export const TableRowState = z.union([TableRowStateSuccess, TableRowStateFailure, TableRowStateLoading])

export interface TableRow {
    id: TableRowId
    position: Position
    size: Size
    source: SourceId
    table: TableId
    primaryKey: RowPrimaryKey
    state: TableRowState
    hidden?: ColumnPathStr[]
    showHiddenColumns?: boolean
    selected?: boolean
    collapsed?: boolean
}

export const TableRow = z.object({
    id: TableRowId,
    position: Position,
    size: Size,
    source: SourceId,
    table: TableId,
    primaryKey: RowPrimaryKey,
    state: TableRowState,
    hidden: ColumnPathStr.array().optional(),
    showHiddenColumns: z.boolean().optional(),
    selected: z.boolean().optional(),
    collapsed: z.boolean().optional()
}).strict()

export interface Group {
    name: string
    tables: TableId[]
    color: Color
    collapsed?: boolean
}

export const Group = z.object({
    name: z.string(),
    tables: TableId.array(),
    color: Color,
    collapsed: z.boolean().optional()
}).strict()

export interface Layout {
    canvas?: CanvasProps // legacy property, keep it for retro compatibility
    tables: TableProps[]
    tableRows?: TableRow[]
    groups?: Group[]
    memos?: Memo[]
    createdAt: Timestamp
    updatedAt: Timestamp
}

export const Layout = z.object({
    canvas: CanvasProps.optional(),
    tables: TableProps.array(),
    tableRows: TableRow.array().optional(),
    groups: Group.array().optional(),
    memos: Memo.array().optional(),
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
    ignoredRelations?: { [table: string]: ColumnPathStr[] }
    notes?: { [ref: string]: string } // legacy property, keep it for retro compatibility
    metadata?: { [table: TableId]: TableMeta }
    usedLayout?: LayoutName // legacy property, keep it for retro compatibility
    layouts: { [name: LayoutName]: Layout }
    tableRowsSeq?: number
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
    ignoredRelations: z.record(ColumnPathStr.array()).optional(),
    notes: z.record(z.string()).optional(),
    metadata: z.record(TableId, TableMeta).optional(),
    usedLayout: LayoutName.optional(),
    layouts: z.record(LayoutName, Layout),
    tableRowsSeq: z.number().optional(),
    settings: Settings.optional(),
    storage: ProjectStorage,
    visibility: ProjectVisibility,
    createdAt: Timestamp,
    updatedAt: Timestamp,
    version: ProjectVersion
}).strict()

export type ProjectJson = Omit<Project, 'organization' | 'id' | 'storage' | 'visibility' | 'createdAt' | 'updatedAt'> & { _type: 'json' }
export const ProjectJson = Project.omit({organization: true, id: true, storage: true, visibility: true, createdAt: true, updatedAt: true}).extend({_type: z.literal('json')}).strict()

export interface ProjectStats {
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

export const ProjectStats = z.object({
    nbSources: z.number(),
    nbTables: z.number(),
    nbColumns: z.number(),
    nbRelations: z.number(),
    nbTypes: z.number(),
    nbComments: z.number(),
    nbLayouts: z.number(),
    nbNotes: z.number(),
    nbMemos: z.number()
}).strict()

export interface ProjectInfoLocal extends ProjectStats {
    organization?: Organization
    id: ProjectId
    slug: ProjectSlug
    name: ProjectName
    description?: string
    storage: 'local'
    visibility: ProjectVisibility
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
    visibility: ProjectVisibility,
    encodingVersion: ProjectVersion,
    createdAt: Timestamp,
    updatedAt: Timestamp
}).strict()

export type ProjectInfoRemote = Omit<ProjectInfoLocal, 'storage'> & { storage: 'remote' }
export const ProjectInfoRemote = ProjectInfoLocal.omit({storage: true}).extend({storage: z.literal(ProjectStorage.enum.remote)}).strict()
export type ProjectInfoRemoteWithContent = ProjectInfoRemote & { content: ProjectJson }
export type ProjectInfo = ProjectInfoLocal | ProjectInfoRemote
export const ProjectInfo = z.discriminatedUnion('storage', [ProjectInfoLocal, ProjectInfoRemote])
export type ProjectInfoWithContent = ProjectInfoLocal | ProjectInfoRemoteWithContent


export function isLocal(p: ProjectInfo): p is ProjectInfoLocal {
    return p.storage === ProjectStorage.enum.local
}

export function isRemote(p: ProjectInfo): p is ProjectInfoRemote {
    return p.storage === ProjectStorage.enum.remote
}

export function parseTableId(id: TableId): {schema: SchemaName, table: TableName} {
    const [schema, table] = id.split(".")
    return table === undefined ? {schema: "", table: schema} : {schema, table}
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

export function computeStats(p: ProjectJson): ProjectStats {
    // should be the same as `tables`, `relations` and `types` in src/Models/Project.elm
    const tables = groupBy(p.sources.flatMap(s => s.tables), t => `${t.schema}.${t.table}`)
    const relations = groupBy(p.sources.flatMap(s => s.relations), r => `${r.src.table}.${r.src.column}->${r.ref.table}.${r.ref.column}`)
    const types = groupBy(p.sources.flatMap(s => s.types || []), t => `${t.schema}.${t.name}`)

    return Zod.validate({
        nbSources: p.sources.length,
        nbTables: Object.keys(tables).length,
        nbColumns: Object.values(tables).map(same => Math.max(...same.map(t => t.columns.length))).reduce((acc, cols) => acc + cols, 0),
        nbRelations: Object.keys(relations).length,
        nbTypes: Object.keys(types).length,
        nbComments: p.sources.flatMap(s => s.tables.flatMap(t => [t.comment].concat(t.columns.map(c => c.comment)).filter(c => !!c))).length,
        nbLayouts: Object.keys(p.layouts).length,
        nbNotes: Object.keys(p.notes || {}).length,
        nbMemos: Object.values(p.layouts).flatMap(l => l.memos || []).length,
    }, ProjectStats, 'ProjectStats')
}
