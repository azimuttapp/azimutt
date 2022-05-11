import {Timestamp} from "./basics";

export interface Project {
    id: ProjectId
    name: ProjectName
    sources: Source[]
    layout: Layout
    layouts: { [name: LayoutName]: Layout }
    settings?: Settings
    createdAt: Timestamp
    updatedAt: Timestamp
    version: number
}

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
    primaryKey: PrimaryKey
    uniques?: Unique[]
    indexes?: Index[]
    checks?: Check[]
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

export type ProjectId = string
export type ProjectName = string
export type SourceId = string
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
