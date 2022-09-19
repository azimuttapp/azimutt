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
    TableId
} from "./project";
import {OrganizationId} from "./organization";
import {Env} from "../utils/env";

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

export type ElmMsg =
    ClickMsg
    | MouseDownMsg
    | FocusMsg
    | BlurMsg
    | ScrollToMsg
    | FullscreenMsg
    | SetMetaMsg
    | AutofocusWithinMsg
    | GetLegacyProjectsMsg
    | GetProjectMsg
    | CreateProjectTmpMsg
    | CreateProjectMsg
    | UpdateProjectMsg
    | MoveProjectToMsg
    | DeleteProjectMsg
    | DownloadFileMsg
    | GetLocalFileMsg
    | ObserveSizesMsg
    | ListenKeysMsg
    | ConfettiMsg
    | ConfettiPrideMsg
    | TrackPageMsg
    | TrackEventMsg
    | TrackErrorMsg
export type ClickMsg = { kind: 'Click', id: HtmlId }
export type MouseDownMsg = { kind: 'MouseDown', id: HtmlId }
export type FocusMsg = { kind: 'Focus', id: HtmlId }
export type BlurMsg = { kind: 'Blur', id: HtmlId }
export type ScrollToMsg = { kind: 'ScrollTo', id: HtmlId, position: ViewPosition }
export type FullscreenMsg = { kind: 'Fullscreen', maybeId?: HtmlId }
export type SetMetaMsg = { kind: 'SetMeta', title?: string, description?: string, canonical?: string, html?: string, body?: string }
export type AutofocusWithinMsg = { kind: 'AutofocusWithin', id: HtmlId }
export type GetLegacyProjectsMsg = { kind: 'GetLegacyProjects' }
export type GetProjectMsg = { kind: 'GetProject', organization: OrganizationId, project: ProjectId }
export type CreateProjectTmpMsg = { kind: 'CreateProjectTmp', project: Project }
export type CreateProjectMsg = { kind: 'CreateProject', organization: OrganizationId, storage: ProjectStorage, project: Project }
export type UpdateProjectMsg = { kind: 'UpdateProject', project: Project }
export type MoveProjectToMsg = { kind: 'MoveProjectTo', project: Project, storage: ProjectStorage }
export type DeleteProjectMsg = { kind: 'DeleteProject', project: ProjectInfo }
export type DownloadFileMsg = { kind: 'DownloadFile', filename: FileName, content: FileContent }
export type GetLocalFileMsg = { kind: 'GetLocalFile', sourceKind: string, file: File }
export type ObserveSizesMsg = { kind: 'ObserveSizes', ids: HtmlId[] }
export type ListenKeysMsg = { kind: 'ListenKeys', keys: { [id: HotkeyId]: Hotkey[] } }
export type ConfettiMsg = { kind: 'Confetti', id: HtmlId }
export type ConfettiPrideMsg = { kind: 'ConfettiPride' }
export type TrackPageMsg = { kind: 'TrackPage', name: string }
export type TrackEventMsg = { kind: 'TrackEvent', name: string, details?: Data }
export type TrackErrorMsg = { kind: 'TrackError', name: string, details?: Data }

export type JsMsg =
    GotSizes
    | GotLegacyProjects
    | GotProject
    | ProjectDeleted
    | GotLocalFile
    | GotHotkey
    | GotKeyHold
    | GotToast
    | GotTableShow
    | GotTableHide
    | GotTableToggleColumns
    | GotTablePosition
    | GotTableMove
    | GotTableSelect
    | GotTableColor
    | GotColumnShow
    | GotColumnHide
    | GotColumnMove
    | GotFitToScreen
    | Error
export type GotSizes = { kind: 'GotSizes', sizes: ElementSize[] }
export type GotLegacyProjects = { kind: 'GotLegacyProjects', projects: [ProjectId, ProjectInfoLocalLegacy][] }
export type GotProject = { kind: 'GotProject', project?: Project }
export type ProjectDeleted = { kind: 'ProjectDeleted', id: ProjectId }
export type GotLocalFile = { kind: 'GotLocalFile', sourceKind: string, file: File, content: string }
export type GotHotkey = { kind: 'GotHotkey', id: string }
export type GotKeyHold = { kind: 'GotKeyHold', key: string, start: boolean }
export type GotToast = { kind: 'GotToast', level: ToastLevel, message: string }
export type GotTableShow = { kind: 'GotTableShow', id: TableId, position?: Position }
export type GotTableHide = { kind: 'GotTableHide', id: TableId }
export type GotTableToggleColumns = { kind: 'GotTableToggleColumns', id: TableId }
export type GotTablePosition = { kind: 'GotTablePosition', id: TableId, position: Position }
export type GotTableMove = { kind: 'GotTableMove', id: TableId, delta: Delta }
export type GotTableSelect = { kind: 'GotTableSelect', id: TableId }
export type GotTableColor = { kind: 'GotTableColor', id: TableId, color: Color }
export type GotColumnShow = { kind: 'GotColumnShow', ref: ColumnId }
export type GotColumnHide = { kind: 'GotColumnHide', ref: ColumnId }
export type GotColumnMove = { kind: 'GotColumnMove', ref: ColumnId, index: number }
export type GotFitToScreen = { kind: 'GotFitToScreen' }
export type Error = { kind: 'Error', message: string }


// from node_modules/@splitbee/web/src/types.ts but not exported :(
export type Data = { [key: string]: string | number | boolean | undefined | null };

export interface ElementSize {
    id: HtmlId,
    position: PositionViewport,
    size: Size,
    seeds: Delta
}

export type HotkeyId = string

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
