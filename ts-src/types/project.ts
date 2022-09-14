import {DateTime, Timestamp, Uuid} from "./basics";

export interface ProjectInfoWithContent {
    id: ProjectId
    slug: string
    name: ProjectName
    description: string | null
    encoding_version: 1 | 2
    storage_kind: 'azimutt' | 'local'
    content: string | undefined
    nb_sources: number
    nb_tables: number
    nb_columns: number
    nb_relations: number
    nb_types: number
    nb_comments: number
    nb_notes: number
    nb_layouts: number
    created_at: DateTime
    updated_at: DateTime
    archived_at: DateTime | null
}

export interface Project {
    id: ProjectId
    name: ProjectName
    sources: Source[]
    usedLayout: LayoutName
    layouts: { [name: LayoutName]: Layout }
    settings?: Settings
    storage?: ProjectStorage
    createdAt: Timestamp
    updatedAt: Timestamp
    version: number
}

export interface ProjectInfo {
    id: ProjectId
    name: ProjectName
    tables: number
    relations: number
    layouts: number
    storage: ProjectStorage
    createdAt: Timestamp
    updatedAt: Timestamp
}

export type ProjectNoStorage = Omit<Project, 'storage'>
export type ProjectInfoNoStorage = Omit<ProjectInfo, 'storage'>

export interface Source {
    id: SourceId
    name: SourceName
    kind: SourceKind
    content: Line[]
    tables: Table[]
    relations: Relation[]
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

// 'browser' was changed for 'local' and 'cloud' for 'azimutt', keep them here for legacy projects
export type ProjectStorage = 'local' | 'azimutt' | 'browser' | 'cloud'

export const ProjectStorage: {[key in ProjectStorage]: key} = {
    local: 'local',
    azimutt: 'azimutt',
    browser: 'browser',
    cloud: 'cloud'
}

export type ProjectId = Uuid
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
