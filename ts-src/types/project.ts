import {Slug, Timestamp} from "./basics";
import {Uuid} from "./uuid";
import {legacy, Organization} from "./organization";
import * as Array from "../utils/array";

export interface Project {
    organization: Organization
    id: ProjectId
    slug: ProjectSlug
    name: ProjectName
    description?: string
    sources: Source[]
    notes: { [ref: string]: string } | undefined
    usedLayout: LayoutName
    layouts: { [name: LayoutName]: Layout }
    settings?: Settings
    storage: ProjectStorage
    createdAt: Timestamp
    updatedAt: Timestamp
    version: ProjectVersion
}

export type ProjectJson = Omit<Project, 'organization' | 'id' | 'storage' | 'createdAt' | 'updatedAt'> & { _type: 'json' }
export type ProjectJsonLegacy = Omit<Project, 'organization' | 'slug' | 'description' | 'storage'>
export type ProjectStored = ProjectJson | ProjectJsonLegacy
export type ProjectStoredWithId = [ProjectId, ProjectStored]

export interface ProjectInfoLocal extends ProjectStats {
    organization: Organization
    id: ProjectId
    slug: ProjectSlug
    name: ProjectName
    description?: string
    storage: 'local'
    encodingVersion: ProjectVersion
    createdAt: Timestamp
    updatedAt: Timestamp
}

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

export type ProjectInfoRemote = Omit<ProjectInfoLocal, 'storage'> & { storage: 'remote' }
export type ProjectInfoRemoteWithContent = ProjectInfoRemote & { content: ProjectJson }
export type ProjectInfo = ProjectInfoLocal | ProjectInfoRemote
export type ProjectInfoWithContent = ProjectInfoLocal | ProjectInfoRemoteWithContent
export type ProjectInfoLocalLegacy = Omit<ProjectInfoLocal, 'organization'>

export interface Source {
    id: SourceId
    name: SourceName
    kind: SourceKind
    content: Line[]
    tables: Table[]
    relations: Relation[]
    types: Type[] | undefined
    enabled?: boolean
    createdAt: Timestamp
    updatedAt: Timestamp
}

export type SourceKind = SourceLocale | SourceRemote | SourceUser

export interface SourceLocale {
    kind: 'LocalFile',
    name: string,
    size: number,
    modified: Timestamp
}

export interface SourceRemote {
    kind: 'RemoteFile',
    url: string,
    size: number
}

export interface SourceUser {
    kind: 'UserDefined'
}

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


export interface PrimaryKey {
    name?: string
    columns: ColumnName[]
    origins: Origin[]
}

export interface Unique {
    name: string
    columns: ColumnName[]
    definition?: string
    origins: Origin[]
}

export interface Index {
    name: string
    columns: ColumnName[]
    definition?: string
    origins: Origin[]
}

export interface Check {
    name: string
    columns: ColumnName[]
    predicate?: string
    origins: Origin[]
}

export interface Column {
    name: ColumnName
    type: ColumnType
    nullable?: boolean
    default?: string
    comment?: Comment
    origins: Origin[]
}

export interface Comment {
    text: string
    origins: Origin[]
}


export interface Relation {
    name: RelationName
    src: ColumnRef
    ref: ColumnRef
    origins: Origin[]
}

export interface ColumnRef {
    table: TableId
    column: ColumnName
}


export interface Type {
    schema: SchemaName
    name: TypeName
    value: { enum: string[] } | { definition: string }
    origins: Origin[]
}

export interface Origin {
    id: SourceId
    lines: LineIndex[]
}

export interface Layout {
    canvas: CanvasProps
    tables: TableProps[]
    createdAt: Timestamp
    updatedAt: Timestamp
}

export interface CanvasProps {
    position: Position
    zoom: ZoomLevel
}

export interface TableProps {
    id: TableId
    position: Position
    color: Color
    columns: ColumnName[]
    selected?: boolean
    collapsed?: boolean
}

export interface Position {
    left: number
    top: number
}

export interface Size {
    width: number
    height: number
}

export interface Delta {
    dx: number
    dy: number
}

export interface Settings {
    removedTables?: string
}

export type ProjectVersion = 1 | 2
export type ProjectStorage = 'local' | 'remote'
export const ProjectStorage: { [key in ProjectStorage]: key } = {
    local: 'local',
    remote: 'remote'
}

export function validStorage(value: string): ProjectStorage {
    // 'browser' was changed for 'local' and 'cloud' for 'remote', keep them here for legacy projects
    if (value === ProjectStorage.local || value === 'browser') {
        return ProjectStorage.local
    } else if (value === ProjectStorage.remote || value === 'cloud') {
        return ProjectStorage.remote
    } else {
        throw `Invalid storage ${JSON.stringify(value)}`
    }
}

export type ProjectId = Uuid
export type ProjectSlug = Slug
export type ProjectName = string
export type SourceId = Uuid
export type SourceName = string
export type SchemaName = string
export type TableId = string
export type TableName = string
export type ColumnId = string
export type ColumnName = string
export type ColumnType = string
export type RelationName = string
export type TypeName = string
export type LayoutName = string
export type ZoomLevel = number
export type Line = string
export type LineIndex = number

export type Color =
    'indigo'
    | 'violet'
    | 'purple'
    | 'fuchsia'
    | 'pink'
    | 'rose'
    | 'red'
    | 'orange'
    | 'amber'
    | 'yellow'
    | 'lime'
    | 'green'
    | 'emerald'
    | 'teal'
    | 'cyan'
    | 'sky'
    | 'blue'
    | 'gray'

export function isLocal(p: ProjectInfo): p is ProjectInfoLocal {
    return p.storage === ProjectStorage.local
}

export function isRemote(p: ProjectInfo): p is ProjectInfoRemote {
    return p.storage === ProjectStorage.remote
}

export function isLegacy(p: ProjectStored): p is ProjectJsonLegacy {
    return 'createdAt' in p
}

export function buildProjectRemote(p: ProjectInfoRemote, content: ProjectJson): Project {
    return {
        ...content,
        organization: p.organization,
        id: p.id,
        storage: ProjectStorage.remote,
        createdAt: p.createdAt,
        updatedAt: p.updatedAt
    }
}

export function buildProjectLocal(p: ProjectInfoLocal, content: ProjectJson): Project {
    return {
        ...content,
        organization: p.organization,
        id: p.id,
        storage: ProjectStorage.local,
        createdAt: p.createdAt,
        updatedAt: p.updatedAt
    }
}

export function buildProjectLocalDraft(id: ProjectId, {_type, ...p}: ProjectJson): Project {
    return {...p, organization: legacy, id, slug: id, storage: ProjectStorage.local, createdAt: Date.now(), updatedAt: Date.now()}
}

export function buildProjectLocalLegacy(id: ProjectId, p: ProjectJsonLegacy): Project {
    return {...p, organization: legacy, id, slug: id, storage: ProjectStorage.local}
}

export function buildProjectJson({organization, id, storage, createdAt, updatedAt, ...p}: Project): ProjectJson {
    return {...p, _type: 'json'}
}

export function computeStats(p: ProjectStored): ProjectStats {
    // should be the same as `fromProject` in src/Models/ProjectInfo.elm
    const tables = Array.groupBy(p.sources.flatMap(s => s.tables), t => `${t.schema}.${t.table}`)
    const types = Array.groupBy(p.sources.flatMap(s => s.types || []), t => `${t.schema}.${t.name}`)

    return {
        nbSources: p.sources.length,
        nbTables: Object.keys(tables).length,
        nbColumns: Object.values(tables).map(same => Math.max(...same.map(t => t.columns.length))).reduce((acc, cols) => acc + cols, 0),
        nbRelations: p.sources.reduce((acc, src) => acc + src.relations.length, 0),
        nbTypes: Object.keys(types).length,
        nbComments: p.sources.flatMap(s => s.tables.flatMap(t => [t.comment].concat(t.columns.map(c => c.comment)).filter(c => !!c))).length,
        nbNotes: Object.keys(p.notes || {}).length,
        nbLayouts: Object.keys(p.layouts).length
    }
}
