import {
    Color,
    Delta,
    FileContent,
    FileName,
    FileObject,
    HtmlId,
    Platform,
    Position,
    PositionViewport,
    Size,
    Timestamp,
    ToastLevel,
    ViewPosition
} from "./basics";
import {
    ColumnId,
    Project,
    ProjectId,
    ProjectInfo,
    ProjectInfoLocalLegacy,
    ProjectStorage,
    SourceOrigin,
    TableId
} from "./project";
import {OrganizationId} from "./organization";
import {Env} from "../utils/env";
import {z} from "zod";

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
    meta: boolean
    target: { id: string | null, class: string | null, tag: string | null } | null
    onInput: boolean
    preventDefault: boolean
}

export const Hotkey = z.object({
    key: z.string(),
    ctrl: z.boolean(),
    shift: z.boolean(),
    alt: z.boolean(),
    meta: z.boolean(),
    target: z.object({
        id: z.string().nullable(),
        class: z.string().nullable(),
        tag: z.string().nullable()
    }).strict().nullable(),
    onInput: z.boolean(),
    preventDefault: z.boolean()
}).strict()

// from node_modules/@splitbee/web/src/types.ts but not exported :(
export type Data = { [key: string]: string | number | boolean | undefined | null };
export const Data = z.record(z.union([z.string(), z.number(), z.boolean(), z.undefined(), z.null()]))


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
export type Fullscreen = { kind: 'Fullscreen', maybeId?: HtmlId }
export const Fullscreen = z.object({kind: z.literal('Fullscreen'), maybeId: HtmlId.optional()}).strict()
export type SetMeta = { kind: 'SetMeta', title: string | null, description: string | null, canonical: string | null, html: string | null, body: string | null }
export const SetMeta = z.object({kind: z.literal('SetMeta'), title: z.string().nullable(), description: z.string().nullable(), canonical: z.string().nullable(), html: z.string().nullable(), body: z.string().nullable()}).strict()
export type AutofocusWithin = { kind: 'AutofocusWithin', id: HtmlId }
export const AutofocusWithin = z.object({kind: z.literal('AutofocusWithin'), id: HtmlId}).strict()
export type GetLegacyProjects = { kind: 'GetLegacyProjects' }
export const GetLegacyProjects = z.object({kind: z.literal('GetLegacyProjects')}).strict()
export type GetProject = { kind: 'GetProject', organization: OrganizationId, project: ProjectId }
export const GetProject = z.object({kind: z.literal('GetProject'), organization: OrganizationId, project: ProjectId}).strict()
export type CreateProjectTmp = { kind: 'CreateProjectTmp', project: Project }
export const CreateProjectTmp = z.object({kind: z.literal('CreateProjectTmp'), project: Project}).strict()
export type CreateProject = { kind: 'CreateProject', organization: OrganizationId, storage: ProjectStorage, project: Project }
export const CreateProject = z.object({kind: z.literal('CreateProject'), organization: OrganizationId, storage: ProjectStorage, project: Project}).strict()
export type UpdateProject = { kind: 'UpdateProject', project: Project }
export const UpdateProject = z.object({kind: z.literal('UpdateProject'), project: Project}).strict()
export type MoveProjectTo = { kind: 'MoveProjectTo', project: Project, storage: ProjectStorage }
export const MoveProjectTo = z.object({kind: z.literal('MoveProjectTo'), project: Project, storage: ProjectStorage}).strict()
export type DeleteProject = { kind: 'DeleteProject', project: ProjectInfo, redirect: string | null }
export const DeleteProject = z.object({kind: z.literal('DeleteProject'), project: ProjectInfo, redirect: z.string().nullable()}).strict()
export type DownloadFile = { kind: 'DownloadFile', filename: FileName, content: FileContent }
export const DownloadFile = z.object({kind: z.literal('DownloadFile'), filename: FileName, content: FileContent}).strict()
export type GetLocalFile = { kind: 'GetLocalFile', sourceKind: SourceOrigin, file: File }
export const GetLocalFile = z.object({kind: z.literal('GetLocalFile'), sourceKind: SourceOrigin, file: FileObject}).strict()
export type ObserveSizes = { kind: 'ObserveSizes', ids: HtmlId[] }
export const ObserveSizes = z.object({kind: z.literal('ObserveSizes'), ids: HtmlId.array()}).strict()
export type ListenKeys = { kind: 'ListenKeys', keys: { [id: HotkeyId]: Hotkey[] } }
export const ListenKeys = z.object({kind: z.literal('ListenKeys'), keys: z.record(HotkeyId, Hotkey.array())}).strict()
export type Confetti = { kind: 'Confetti', id: HtmlId }
export const Confetti = z.object({kind: z.literal('Confetti'), id: HtmlId}).strict()
export type ConfettiPride = { kind: 'ConfettiPride' }
export const ConfettiPride = z.object({kind: z.literal('ConfettiPride')}).strict()
export type TrackPage = { kind: 'TrackPage', name: string }
export const TrackPage = z.object({kind: z.literal('TrackPage'), name: z.string()}).strict()
export type TrackEvent = { kind: 'TrackEvent', name: string, details?: Data }
export const TrackEvent = z.object({kind: z.literal('TrackEvent'), name: z.string(), details: Data.optional()}).strict()
export type TrackError = { kind: 'TrackError', name: string, details?: Data }
export const TrackError = z.object({kind: z.literal('TrackError'), name: z.string(), details: Data.optional()}).strict()
export type ElmMsg = Click | MouseDown | Focus | Blur | ScrollTo | Fullscreen | SetMeta | AutofocusWithin | GetLegacyProjects | GetProject | CreateProjectTmp | CreateProject | UpdateProject | MoveProjectTo | DeleteProject | DownloadFile | GetLocalFile | ObserveSizes | ListenKeys | Confetti | ConfettiPride | TrackPage | TrackEvent | TrackError
export const ElmMsg = z.discriminatedUnion('kind', [Click, MouseDown, Focus, Blur, ScrollTo, Fullscreen, SetMeta, AutofocusWithin, GetLegacyProjects, GetProject, CreateProjectTmp, CreateProject, UpdateProject, MoveProjectTo, DeleteProject, DownloadFile, GetLocalFile, ObserveSizes, ListenKeys, Confetti, ConfettiPride, TrackPage, TrackEvent, TrackError])


export type GotSizes = { kind: 'GotSizes', sizes: ElementSize[] }
export const GotSizes = z.object({kind: z.literal('GotSizes'), sizes: ElementSize.array()}).strict()
export type GotLegacyProjects = { kind: 'GotLegacyProjects', projects: [ProjectId, ProjectInfoLocalLegacy][] }
export const GotLegacyProjects = z.object({kind: z.literal('GotLegacyProjects'), projects: z.tuple([ProjectId, ProjectInfoLocalLegacy]).array()}).strict()
export type GotProject = { kind: 'GotProject', project?: Project }
export const GotProject = z.object({kind: z.literal('GotProject'), project: Project.optional()}).strict()
export type ProjectDeleted = { kind: 'ProjectDeleted', id: ProjectId }
export const ProjectDeleted = z.object({kind: z.literal('ProjectDeleted'), id: ProjectId}).strict()
export type GotLocalFile = { kind: 'GotLocalFile', sourceKind: SourceOrigin, file: File, content: string }
export const GotLocalFile = z.object({kind: z.literal('GotLocalFile'), sourceKind: SourceOrigin, file: FileObject, content: z.string()}).strict()
export type GotHotkey = { kind: 'GotHotkey', id: string }
export const GotHotkey = z.object({kind: z.literal('GotHotkey'), id: z.string()}).strict()
export type GotKeyHold = { kind: 'GotKeyHold', key: string, start: boolean }
export const GotKeyHold = z.object({kind: z.literal('GotKeyHold'), key: z.string(), start: z.boolean()}).strict()
export type GotToast = { kind: 'GotToast', level: ToastLevel, message: string }
export const GotToast = z.object({kind: z.literal('GotToast'), level: ToastLevel, message: z.string()}).strict()
export type GotTableShow = { kind: 'GotTableShow', id: TableId, position?: Position }
export const GotTableShow = z.object({kind: z.literal('GotTableShow'), id: TableId, position: Position.optional()}).strict()
export type GotTableHide = { kind: 'GotTableHide', id: TableId }
export const GotTableHide = z.object({kind: z.literal('GotTableHide'), id: TableId}).strict()
export type GotTableToggleColumns = { kind: 'GotTableToggleColumns', id: TableId }
export const GotTableToggleColumns = z.object({kind: z.literal('GotTableToggleColumns'), id: TableId}).strict()
export type GotTablePosition = { kind: 'GotTablePosition', id: TableId, position: Position }
export const GotTablePosition = z.object({kind: z.literal('GotTablePosition'), id: TableId, position: Position}).strict()
export type GotTableMove = { kind: 'GotTableMove', id: TableId, delta: Delta }
export const GotTableMove = z.object({kind: z.literal('GotTableMove'), id: TableId, delta: Delta}).strict()
export type GotTableSelect = { kind: 'GotTableSelect', id: TableId }
export const GotTableSelect = z.object({kind: z.literal('GotTableSelect'), id: TableId}).strict()
export type GotTableColor = { kind: 'GotTableColor', id: TableId, color: Color }
export const GotTableColor = z.object({kind: z.literal('GotTableColor'), id: TableId, color: Color}).strict()
export type GotColumnShow = { kind: 'GotColumnShow', ref: ColumnId }
export const GotColumnShow = z.object({kind: z.literal('GotColumnShow'), ref: ColumnId}).strict()
export type GotColumnHide = { kind: 'GotColumnHide', ref: ColumnId }
export const GotColumnHide = z.object({kind: z.literal('GotColumnHide'), ref: ColumnId}).strict()
export type GotColumnMove = { kind: 'GotColumnMove', ref: ColumnId, index: number }
export const GotColumnMove = z.object({kind: z.literal('GotColumnMove'), ref: ColumnId, index: z.number()}).strict()
export type GotFitToScreen = { kind: 'GotFitToScreen' }
export const GotFitToScreen = z.object({kind: z.literal('GotFitToScreen')}).strict()
export type Error = { kind: 'Error', message: string }
export const Error = z.object({kind: z.literal('Error'), message: z.string()}).strict()
export type JsMsg = GotSizes | GotLegacyProjects | GotProject | ProjectDeleted | GotLocalFile | GotHotkey | GotKeyHold | GotToast | GotTableShow | GotTableHide | GotTableToggleColumns | GotTablePosition | GotTableMove | GotTableSelect | GotTableColor | GotColumnShow | GotColumnHide | GotColumnMove | GotFitToScreen | Error
export const JsMsg = z.discriminatedUnion('kind', [GotSizes, GotLegacyProjects, GotProject, ProjectDeleted, GotLocalFile, GotHotkey, GotKeyHold, GotToast, GotTableShow, GotTableHide, GotTableToggleColumns, GotTablePosition, GotTableMove, GotTableSelect, GotTableColor, GotColumnShow, GotColumnHide, GotColumnMove, GotFitToScreen, Error])
