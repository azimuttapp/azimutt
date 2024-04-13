import {
    Color,
    DatabaseUrl,
    Delta,
    LegacyColumnId,
    LegacyColumnRef,
    LegacyColumnStats,
    LegacyDatabase,
    LegacyDatabaseQueryResultsColumn,
    LegacyJsValue,
    LegacyOrganizationId,
    LegacyProject,
    LegacyProjectId,
    LegacyProjectInfo,
    LegacyProjectStorage,
    LegacyProjectTokenId,
    LegacySourceId,
    LegacySourceOrigin,
    LegacySqlQueryOrigin,
    LegacyTableId,
    LegacyTableStats,
    Position,
    Size,
    Timestamp
} from "@azimutt/models";
import {
    FileContent,
    FileName,
    FileObject,
    HtmlId,
    Platform,
    PositionViewport,
    ToastLevel,
    ViewPosition
} from "./basics";
import {Env} from "../utils/env";
import {z} from "zod";
import {TrackEvent} from "./tracking";

export interface ElmProgram<F, I, O> {
    init: (f: { flags: F, node?: HTMLElement }) => ElmRuntime<I, O>
}

export interface ElmRuntime<I, O> {
    ports?: {
        jsToElm: { send: (msg: I) => void }
        elmToJs: { subscribe: (callback: (msg: O) => void) => void }
    }
}

export interface ElmFlags {
    now: Timestamp
    conf: {
        env: Env
        platform: Platform
        desktop: boolean
    }
}

export interface ElementSize {
    id: HtmlId
    position: PositionViewport
    size: Size
    seeds: Delta
}

export const ElementSize = z.object({
    id: HtmlId,
    position: PositionViewport,
    size: Size,
    seeds: Delta
}).strict()

export type HotkeyId = string
export const HotkeyId = z.string()

export interface Hotkey {
    key: string
    ctrl: boolean
    shift: boolean
    alt: boolean
    target: { id: string | null, class: string | null, tag: string | null } | null
    onInput: boolean
    preventDefault: boolean
}

export const Hotkey = z.object({
    key: z.string(),
    ctrl: z.boolean(),
    shift: z.boolean(),
    alt: z.boolean(),
    target: z.object({
        id: z.string().nullable(),
        class: z.string().nullable(),
        tag: z.string().nullable()
    }).strict().nullable(),
    onInput: z.boolean(),
    preventDefault: z.boolean()
}).strict()


export type Click = { kind: 'Click', id: HtmlId }
export const Click = z.object({kind: z.literal('Click'), id: HtmlId}).strict()
export type MouseDown = { kind: 'MouseDown', id: HtmlId }
export const MouseDown = z.object({kind: z.literal('MouseDown'), id: HtmlId}).strict()
export type Focus = { kind: 'Focus', id: HtmlId }
export const Focus = z.object({kind: z.literal('Focus'), id: HtmlId}).strict()
export type Blur = { kind: 'Blur', id: HtmlId }
export const Blur = z.object({kind: z.literal('Blur'), id: HtmlId}).strict()
export type ScrollTo = { kind: 'ScrollTo', id: HtmlId, position: ViewPosition }
export const ScrollTo = z.object({kind: z.literal('ScrollTo'), id: HtmlId, position: ViewPosition}).strict()
export type Fullscreen = { kind: 'Fullscreen', id?: HtmlId }
export const Fullscreen = z.object({kind: z.literal('Fullscreen'), id: HtmlId.optional()}).strict()
export type SetMeta = { kind: 'SetMeta', title: string | null, description: string | null, canonical: string | null, html: string | null, body: string | null }
export const SetMeta = z.object({kind: z.literal('SetMeta'), title: z.string().nullable(), description: z.string().nullable(), canonical: z.string().nullable(), html: z.string().nullable(), body: z.string().nullable()}).strict()
export type AutofocusWithin = { kind: 'AutofocusWithin', id: HtmlId }
export const AutofocusWithin = z.object({kind: z.literal('AutofocusWithin'), id: HtmlId}).strict()
export type Toast = { kind: 'Toast', level: ToastLevel, message: string }
export const Toast = z.object({kind: z.literal('Toast'), level: ToastLevel, message: z.string()}).strict()
export type GetProject = { kind: 'GetProject', organization: LegacyOrganizationId, project: LegacyProjectId, token: LegacyProjectTokenId | null }
export const GetProject = z.object({kind: z.literal('GetProject'), organization: LegacyOrganizationId, project: LegacyProjectId, token: LegacyProjectTokenId.nullable()}).strict()
export type CreateProjectTmp = { kind: 'CreateProjectTmp', project: LegacyProject }
export const CreateProjectTmp = z.object({kind: z.literal('CreateProjectTmp'), project: LegacyProject}).strict()
export type UpdateProjectTmp = { kind: 'UpdateProjectTmp', project: LegacyProject }
export const UpdateProjectTmp = z.object({kind: z.literal('UpdateProjectTmp'), project: LegacyProject}).strict()
export type CreateProject = { kind: 'CreateProject', organization: LegacyOrganizationId, storage: LegacyProjectStorage, project: LegacyProject }
export const CreateProject = z.object({kind: z.literal('CreateProject'), organization: LegacyOrganizationId, storage: LegacyProjectStorage, project: LegacyProject}).strict()
export type UpdateProject = { kind: 'UpdateProject', project: LegacyProject }
export const UpdateProject = z.object({kind: z.literal('UpdateProject'), project: LegacyProject}).strict()
export type MoveProjectTo = { kind: 'MoveProjectTo', project: LegacyProject, storage: LegacyProjectStorage }
export const MoveProjectTo = z.object({kind: z.literal('MoveProjectTo'), project: LegacyProject, storage: LegacyProjectStorage}).strict()
export type DeleteProject = { kind: 'DeleteProject', project: LegacyProjectInfo, redirect: string | null }
export const DeleteProject = z.object({kind: z.literal('DeleteProject'), project: LegacyProjectInfo, redirect: z.string().nullable()}).strict()
export type ProjectDirty = { kind: 'ProjectDirty', dirty: boolean }
export const ProjectDirty = z.object({kind: z.literal('ProjectDirty'), dirty: z.boolean()}).strict()
export type DownloadFile = { kind: 'DownloadFile', filename: FileName, content: FileContent }
export const DownloadFile = z.object({kind: z.literal('DownloadFile'), filename: FileName, content: FileContent}).strict()
export type CopyToClipboard = { kind: 'CopyToClipboard', content: string }
export const CopyToClipboard = z.object({kind: z.literal('CopyToClipboard'), content: z.string()}).strict()
export type GetLocalFile = { kind: 'GetLocalFile', sourceKind: LegacySourceOrigin, file: File }
export const GetLocalFile = z.object({kind: z.literal('GetLocalFile'), sourceKind: LegacySourceOrigin, file: FileObject}).strict()
export type GetDatabaseSchema = { kind: 'GetDatabaseSchema', database: DatabaseUrl }
export const GetDatabaseSchema = z.object({kind: z.literal('GetDatabaseSchema'), database: DatabaseUrl}).strict()
export type GetTableStats = { kind: 'GetTableStats', source: LegacySourceId, database: DatabaseUrl, table: LegacyTableId }
export const GetTableStats = z.object({kind: z.literal('GetTableStats'), source: LegacySourceId, database: DatabaseUrl, table: LegacyTableId}).strict()
export type GetColumnStats = { kind: 'GetColumnStats', source: LegacySourceId, database: DatabaseUrl, column: LegacyColumnRef }
export const GetColumnStats = z.object({kind: z.literal('GetColumnStats'), source: LegacySourceId, database: DatabaseUrl, column: LegacyColumnRef}).strict()
export type RunDatabaseQuery = { kind: 'RunDatabaseQuery', context: string, database: DatabaseUrl, query: LegacySqlQueryOrigin }
export const RunDatabaseQuery = z.object({kind: z.literal('RunDatabaseQuery'), context: z.string(), database: DatabaseUrl, query: LegacySqlQueryOrigin}).strict()
export type GetPrismaSchema = { kind: 'GetPrismaSchema', content: string }
export const GetPrismaSchema = z.object({kind: z.literal('GetPrismaSchema'), content: z.string()}).strict()
export type ObserveSizes = { kind: 'ObserveSizes', ids: HtmlId[] }
export const ObserveSizes = z.object({kind: z.literal('ObserveSizes'), ids: HtmlId.array()}).strict()
export type ListenKeys = { kind: 'ListenKeys', keys: { [id: HotkeyId]: Hotkey[] } }
export const ListenKeys = z.object({kind: z.literal('ListenKeys'), keys: z.record(HotkeyId, Hotkey.array())}).strict()
export type Confetti = { kind: 'Confetti', id: HtmlId }
export const Confetti = z.object({kind: z.literal('Confetti'), id: HtmlId}).strict()
export type ConfettiPride = { kind: 'ConfettiPride' }
export const ConfettiPride = z.object({kind: z.literal('ConfettiPride')}).strict()
export type Fireworks = { kind: 'Fireworks' }
export const Fireworks = z.object({kind: z.literal('Fireworks')}).strict()
export type Track = { kind: 'Track', event: TrackEvent }
export const Track = z.object({kind: z.literal('Track'), event: TrackEvent}).strict()
export type ElmMsg = Click | MouseDown | Focus | Blur | ScrollTo | Fullscreen | SetMeta | AutofocusWithin | Toast | GetProject | CreateProjectTmp | UpdateProjectTmp | CreateProject | UpdateProject | MoveProjectTo | DeleteProject | ProjectDirty | DownloadFile | CopyToClipboard | GetLocalFile | GetDatabaseSchema | GetTableStats | GetColumnStats | RunDatabaseQuery | GetPrismaSchema | ObserveSizes | ListenKeys | Confetti | ConfettiPride | Fireworks | Track
export const ElmMsg = z.discriminatedUnion('kind', [Click, MouseDown, Focus, Blur, ScrollTo, Fullscreen, SetMeta, AutofocusWithin, Toast, GetProject, CreateProjectTmp, UpdateProjectTmp, CreateProject, UpdateProject, MoveProjectTo, DeleteProject, ProjectDirty, DownloadFile, CopyToClipboard, GetLocalFile, GetDatabaseSchema, GetTableStats, GetColumnStats, RunDatabaseQuery, GetPrismaSchema, ObserveSizes, ListenKeys, Confetti, ConfettiPride, Fireworks, Track])


export type GotSizes = { kind: 'GotSizes', sizes: ElementSize[] }
export const GotSizes = z.object({kind: z.literal('GotSizes'), sizes: ElementSize.array()}).strict()
export type GotProject = { kind: 'GotProject', context: string, project?: LegacyProject }
export const GotProject = z.object({kind: z.literal('GotProject'), context: z.string(), project: LegacyProject.optional()}).strict()
export type ProjectDeleted = { kind: 'ProjectDeleted', id: LegacyProjectId }
export const ProjectDeleted = z.object({kind: z.literal('ProjectDeleted'), id: LegacyProjectId}).strict()
export type GotLocalFile = { kind: 'GotLocalFile', sourceKind: LegacySourceOrigin, file: File, content: string }
export const GotLocalFile = z.object({kind: z.literal('GotLocalFile'), sourceKind: LegacySourceOrigin, file: FileObject, content: z.string()}).strict()
export type GotDatabaseSchema = { kind: 'GotDatabaseSchema', schema: LegacyDatabase }
export const GotDatabaseSchema = z.object({kind: z.literal('GotDatabaseSchema'), schema: LegacyDatabase}).strict()
export type GotDatabaseSchemaError = { kind: 'GotDatabaseSchemaError', error: string }
export const GotDatabaseSchemaError = z.object({kind: z.literal('GotDatabaseSchemaError'), error: z.string()}).strict()
export type GotTableStats = { kind: 'GotTableStats', source: LegacySourceId, stats: LegacyTableStats }
export const GotTableStats = z.object({kind: z.literal('GotTableStats'), source: LegacySourceId, stats: LegacyTableStats}).strict()
export type GotTableStatsError = { kind: 'GotTableStatsError', source: LegacySourceId, table: LegacyTableId, error: string }
export const GotTableStatsError = z.object({kind: z.literal('GotTableStatsError'), source: LegacySourceId, table: LegacyTableId, error: z.string()}).strict()
export type GotColumnStats = { kind: 'GotColumnStats', source: LegacySourceId, stats: LegacyColumnStats }
export const GotColumnStats = z.object({kind: z.literal('GotColumnStats'), source: LegacySourceId, stats: LegacyColumnStats}).strict()
export type GotColumnStatsError = { kind: 'GotColumnStatsError', source: LegacySourceId, column: LegacyColumnRef, error: string }
export const GotColumnStatsError = z.object({kind: z.literal('GotColumnStatsError'), source: LegacySourceId, column: LegacyColumnRef, error: z.string()}).strict()
export type GotDatabaseQueryResult = { kind: 'GotDatabaseQueryResult', context: string, query: LegacySqlQueryOrigin, result: string | {columns: LegacyDatabaseQueryResultsColumn[], rows: LegacyJsValue[]}, started: number, finished: number }
export const GotDatabaseQueryResult = z.object({kind: z.literal('GotDatabaseQueryResult'), context: z.string(), query: LegacySqlQueryOrigin, result: z.union([z.string(), z.object({columns: LegacyDatabaseQueryResultsColumn.array(), rows: LegacyJsValue.array() })]), started: z.number(), finished: z.number()}).strict()
export type GotPrismaSchema = { kind: 'GotPrismaSchema', schema: LegacyDatabase }
export const GotPrismaSchema = z.object({kind: z.literal('GotPrismaSchema'), schema: LegacyDatabase}).strict()
export type GotPrismaSchemaError = { kind: 'GotPrismaSchemaError', error: string }
export const GotPrismaSchemaError = z.object({kind: z.literal('GotPrismaSchemaError'), error: z.string()}).strict()
export type GotHotkey = { kind: 'GotHotkey', id: string }
export const GotHotkey = z.object({kind: z.literal('GotHotkey'), id: z.string()}).strict()
export type GotKeyHold = { kind: 'GotKeyHold', key: string, start: boolean }
export const GotKeyHold = z.object({kind: z.literal('GotKeyHold'), key: z.string(), start: z.boolean()}).strict()
export type GotToast = { kind: 'GotToast', level: ToastLevel, message: string }
export const GotToast = z.object({kind: z.literal('GotToast'), level: ToastLevel, message: z.string()}).strict()
export type GotTableShow = { kind: 'GotTableShow', id: LegacyTableId, position?: Position }
export const GotTableShow = z.object({kind: z.literal('GotTableShow'), id: LegacyTableId, position: Position.optional()}).strict()
export type GotTableHide = { kind: 'GotTableHide', id: LegacyTableId }
export const GotTableHide = z.object({kind: z.literal('GotTableHide'), id: LegacyTableId}).strict()
export type GotTableToggleColumns = { kind: 'GotTableToggleColumns', id: LegacyTableId }
export const GotTableToggleColumns = z.object({kind: z.literal('GotTableToggleColumns'), id: LegacyTableId}).strict()
export type GotTablePosition = { kind: 'GotTablePosition', id: LegacyTableId, position: Position }
export const GotTablePosition = z.object({kind: z.literal('GotTablePosition'), id: LegacyTableId, position: Position}).strict()
export type GotTableMove = { kind: 'GotTableMove', id: LegacyTableId, delta: Delta }
export const GotTableMove = z.object({kind: z.literal('GotTableMove'), id: LegacyTableId, delta: Delta}).strict()
export type GotTableSelect = { kind: 'GotTableSelect', id: LegacyTableId }
export const GotTableSelect = z.object({kind: z.literal('GotTableSelect'), id: LegacyTableId}).strict()
export type GotTableColor = { kind: 'GotTableColor', id: LegacyTableId, color: Color }
export const GotTableColor = z.object({kind: z.literal('GotTableColor'), id: LegacyTableId, color: Color}).strict()
export type GotColumnShow = { kind: 'GotColumnShow', ref: LegacyColumnId }
export const GotColumnShow = z.object({kind: z.literal('GotColumnShow'), ref: LegacyColumnId}).strict()
export type GotColumnHide = { kind: 'GotColumnHide', ref: LegacyColumnId }
export const GotColumnHide = z.object({kind: z.literal('GotColumnHide'), ref: LegacyColumnId}).strict()
export type GotColumnMove = { kind: 'GotColumnMove', ref: LegacyColumnId, index: number }
export const GotColumnMove = z.object({kind: z.literal('GotColumnMove'), ref: LegacyColumnId, index: z.number()}).strict()
export type GotFitToScreen = { kind: 'GotFitToScreen' }
export const GotFitToScreen = z.object({kind: z.literal('GotFitToScreen')}).strict()
export type Error = { kind: 'Error', message: string }
export const Error = z.object({kind: z.literal('Error'), message: z.string()}).strict()
export type JsMsg = GotSizes | GotProject | ProjectDeleted | GotLocalFile | GotDatabaseSchema | GotDatabaseSchemaError | GotTableStats | GotTableStatsError | GotColumnStats | GotColumnStatsError | GotDatabaseQueryResult | GotPrismaSchema | GotPrismaSchemaError | GotHotkey | GotKeyHold | GotToast | GotTableShow | GotTableHide | GotTableToggleColumns | GotTablePosition | GotTableMove | GotTableSelect | GotTableColor | GotColumnShow | GotColumnHide | GotColumnMove | GotFitToScreen | Error
export const JsMsg = z.discriminatedUnion('kind', [GotSizes, GotProject, ProjectDeleted, GotLocalFile, GotDatabaseSchema, GotDatabaseSchemaError, GotTableStats, GotTableStatsError, GotColumnStats, GotColumnStatsError, GotDatabaseQueryResult, GotPrismaSchema, GotPrismaSchemaError, GotHotkey, GotKeyHold, GotToast, GotTableShow, GotTableHide, GotTableToggleColumns, GotTablePosition, GotTableMove, GotTableSelect, GotTableColor, GotColumnShow, GotColumnHide, GotColumnMove, GotFitToScreen, Error])
