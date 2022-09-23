import {
    File,
    FileContent,
    FileName,
    HtmlId,
    Platform,
    PositionViewport,
    Timestamp,
    ToastLevel,
    ViewPosition
} from "./basics";
import {
    Color,
    ColumnId,
    Delta,
    Position,
    Project,
    ProjectId,
    ProjectInfo,
    ProjectInfoLocalLegacy,
    ProjectStorage,
    Size,
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
    target?: { id?: string, class?: string, tag?: string }
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
        id: z.string().optional(),
        class: z.string().optional(),
        tag: z.string().optional()
    }).strict().optional(),
    onInput: z.boolean(),
    preventDefault: z.boolean()
}).strict()

// from node_modules/@splitbee/web/src/types.ts but not exported :(
export type Data = { [key: string]: string | number | boolean | undefined | null };
export const Data = z.record(z.union([z.string(), z.number(), z.boolean(), z.undefined(), z.null()]))


export type ClickMsg = { kind: 'Click', id: HtmlId }
export const ClickMsg = z.object({kind: z.literal('Click'), id: HtmlId}).strict()
export type MouseDownMsg = { kind: 'MouseDown', id: HtmlId }
export const MouseDownMsg = z.object({kind: z.literal('MouseDown'), id: HtmlId}).strict()
export type FocusMsg = { kind: 'Focus', id: HtmlId }
export const FocusMsg = z.object({kind: z.literal('Focus'), id: HtmlId}).strict()
export type BlurMsg = { kind: 'Blur', id: HtmlId }
export const BlurMsg = z.object({kind: z.literal('Blur'), id: HtmlId}).strict()
export type ScrollToMsg = { kind: 'ScrollTo', id: HtmlId, position: ViewPosition }
export const ScrollToMsg = z.object({kind: z.literal('ScrollTo'), id: HtmlId, position: ViewPosition}).strict()
export type FullscreenMsg = { kind: 'Fullscreen', maybeId?: HtmlId }
export const FullscreenMsg = z.object({kind: z.literal('Fullscreen'), maybeId: HtmlId.optional()}).strict()
export type SetMetaMsg = { kind: 'SetMeta', title?: string, description?: string, canonical?: string, html?: string, body?: string }
export const SetMetaMsg = z.object({kind: z.literal('SetMeta'), title: z.string().optional(), description: z.string().optional(), canonical: z.string().optional(), html: z.string().optional(), body: z.string().optional()}).strict()
export type AutofocusWithinMsg = { kind: 'AutofocusWithin', id: HtmlId }
export const AutofocusWithinMsg = z.object({kind: z.literal('AutofocusWithin'), id: HtmlId}).strict()
export type GetLegacyProjectsMsg = { kind: 'GetLegacyProjects' }
export const GetLegacyProjectsMsg = z.object({kind: z.literal('GetLegacyProjects')}).strict()
export type GetProjectMsg = { kind: 'GetProject', organization: OrganizationId, project: ProjectId }
export const GetProjectMsg = z.object({kind: z.literal('GetProject'), organization: OrganizationId, project: ProjectId}).strict()
export type CreateProjectTmpMsg = { kind: 'CreateProjectTmp', project: Project }
export const CreateProjectTmpMsg = z.object({kind: z.literal('CreateProjectTmp'), project: Project}).strict()
export type CreateProjectMsg = { kind: 'CreateProject', organization: OrganizationId, storage: ProjectStorage, project: Project }
export const CreateProjectMsg = z.object({kind: z.literal('CreateProject'), organization: OrganizationId, storage: ProjectStorage, project: Project}).strict()
export type UpdateProjectMsg = { kind: 'UpdateProject', project: Project }
export const UpdateProjectMsg = z.object({kind: z.literal('UpdateProject'), project: Project}).strict()
export type MoveProjectToMsg = { kind: 'MoveProjectTo', project: Project, storage: ProjectStorage }
export const MoveProjectToMsg = z.object({kind: z.literal('MoveProjectTo'), project: Project, storage: ProjectStorage}).strict()
export type DeleteProjectMsg = { kind: 'DeleteProject', project: ProjectInfo }
export const DeleteProjectMsg = z.object({kind: z.literal('DeleteProject'), project: ProjectInfo}).strict()
export type DownloadFileMsg = { kind: 'DownloadFile', filename: FileName, content: FileContent }
export const DownloadFileMsg = z.object({kind: z.literal('DownloadFile'), filename: FileName, content: FileContent}).strict()
export type GetLocalFileMsg = { kind: 'GetLocalFile', sourceKind: SourceOrigin, file: File }
export const GetLocalFileMsg = z.object({kind: z.literal('GetLocalFile'), sourceKind: SourceOrigin, file: File}).strict()
export type ObserveSizesMsg = { kind: 'ObserveSizes', ids: HtmlId[] }
export const ObserveSizesMsg = z.object({kind: z.literal('ObserveSizes'), ids: HtmlId.array()}).strict()
export type ListenKeysMsg = { kind: 'ListenKeys', keys: { [id: HotkeyId]: Hotkey[] } }
export const ListenKeysMsg = z.object({kind: z.literal('ListenKeys'), keys: z.record(HotkeyId, Hotkey.array())}).strict()
export type ConfettiMsg = { kind: 'Confetti', id: HtmlId }
export const ConfettiMsg = z.object({kind: z.literal('Confetti'), id: HtmlId}).strict()
export type ConfettiPrideMsg = { kind: 'ConfettiPride' }
export const ConfettiPrideMsg = z.object({kind: z.literal('ConfettiPride')}).strict()
export type TrackPageMsg = { kind: 'TrackPage', name: string }
export const TrackPageMsg = z.object({kind: z.literal('TrackPage'), name: z.string()}).strict()
export type TrackEventMsg = { kind: 'TrackEvent', name: string, details?: Data }
export const TrackEventMsg = z.object({kind: z.literal('TrackEvent'), name: z.string(), details: Data.optional()}).strict()
export type TrackErrorMsg = { kind: 'TrackError', name: string, details?: Data }
export const TrackErrorMsg = z.object({kind: z.literal('TrackError'), name: z.string(), details: Data.optional()}).strict()
export type ElmMsg = ClickMsg | MouseDownMsg | FocusMsg | BlurMsg | ScrollToMsg | FullscreenMsg | SetMetaMsg | AutofocusWithinMsg | GetLegacyProjectsMsg | GetProjectMsg | CreateProjectTmpMsg | CreateProjectMsg | UpdateProjectMsg | MoveProjectToMsg | DeleteProjectMsg | DownloadFileMsg | GetLocalFileMsg | ObserveSizesMsg | ListenKeysMsg | ConfettiMsg | ConfettiPrideMsg | TrackPageMsg | TrackEventMsg | TrackErrorMsg
export const ElmMsg = z.discriminatedUnion('kind', [ClickMsg, MouseDownMsg, FocusMsg, BlurMsg, ScrollToMsg, FullscreenMsg, SetMetaMsg, AutofocusWithinMsg, GetLegacyProjectsMsg, GetProjectMsg, CreateProjectTmpMsg, CreateProjectMsg, UpdateProjectMsg, MoveProjectToMsg, DeleteProjectMsg, DownloadFileMsg, GetLocalFileMsg, ObserveSizesMsg, ListenKeysMsg, ConfettiMsg, ConfettiPrideMsg, TrackPageMsg, TrackEventMsg, TrackErrorMsg])


export type GotSizes = { kind: 'GotSizes', sizes: ElementSize[] }
export const GotSizes = z.object({kind: z.literal('GotSizes'), sizes: ElementSize.array()}).strict()
export type GotLegacyProjects = { kind: 'GotLegacyProjects', projects: [ProjectId, ProjectInfoLocalLegacy][] }
export const GotLegacyProjects = z.object({kind: z.literal('GotLegacyProjects'), projects: z.tuple([ProjectId, ProjectInfoLocalLegacy]).array()}).strict()
export type GotProject = { kind: 'GotProject', project?: Project }
export const GotProject = z.object({kind: z.literal('GotProject'), project: Project.optional()}).strict()
export type ProjectDeleted = { kind: 'ProjectDeleted', id: ProjectId }
export const ProjectDeleted = z.object({kind: z.literal('ProjectDeleted'), id: ProjectId}).strict()
export type GotLocalFile = { kind: 'GotLocalFile', sourceKind: SourceOrigin, file: File, content: string }
export const GotLocalFile = z.object({kind: z.literal('GotLocalFile'), sourceKind: SourceOrigin, file: File, content: z.string()}).strict()
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
