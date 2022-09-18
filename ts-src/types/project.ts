import {Slug, Timestamp} from "./basics";
import {Uuid} from "./uuid";
import {Organization} from "./organization";
import * as Array from "../utils/array";

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

export interface ProjectInfo extends ProjectStats {
    organization: Organization | undefined
    id: ProjectId
    slug: ProjectSlug
    name: ProjectName
    description: string | null
    encodingVersion: ProjectVersion
    storage: ProjectStorage
    createdAt: Timestamp
    updatedAt: Timestamp
    archivedAt: Timestamp | null
}

export interface ProjectInfoWithContent extends ProjectInfo {
    content: string | undefined
}

export interface Project {
    organization: Organization | undefined
    id: ProjectId
    name: ProjectName
    sources: Source[]
    notes: { [ref: string]: string } | undefined
    usedLayout: LayoutName
    layouts: { [name: LayoutName]: Layout }
    settings?: Settings
    storage?: ProjectStorage
    createdAt: Timestamp
    updatedAt: Timestamp
    version: ProjectVersion
}

export type ProjectWithOrga = Omit<Project, 'organization'> & { organization: Organization }
export type ProjectNoStorage = Omit<Project, 'storage'>
export type ProjectInfoNoStorage = Omit<ProjectInfo, 'storage'>

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

// 'browser' was changed for 'local' and 'cloud' for 'remote', keep them here for legacy projects
export type ProjectStorage = 'local' | 'remote' | 'browser' | 'cloud'

export const ProjectStorage: { [key in ProjectStorage]: key } = {
    local: 'local',
    remote: 'remote',
    browser: 'browser',
    cloud: 'cloud'
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

export function computeStats(p: ProjectNoStorage): ProjectStats {
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

export function projectToInfo(id: ProjectId, p: ProjectNoStorage): ProjectInfoNoStorage {
    return {
        organization: undefined,
        id: id,
        slug: id,
        name: p.name,
        description: null,
        encodingVersion: p.version,
        createdAt: p.createdAt,
        updatedAt: p.updatedAt,
        archivedAt: null,
        ...computeStats(p)
    }
}
