import {File, FileContent, FileName, FileUrl, HtmlId, Timestamp, ToastLevel, ViewPosition} from "./basics";
import {
    Color,
    ColumnId,
    Delta,
    Position,
    Project,
    ProjectId,
    Size,
    SourceId,
    ProjectStorage,
    TableId,
    ProjectInfo
} from "./project";
import {User} from "./user";

export interface ElmFlags {
    now: Timestamp
    user: User | null
}

export interface ElmInit {
    flags: ElmFlags
}

export interface ElmRuntime {
    ports?: ElmPorts
}

export interface ElmPorts {
    jsToElm: InPort<JsMsg>
    elmToJs: OutPort<ElmMsg>
}

export interface InPort<T> {
    send: (msg: T) => void
}

export interface OutPort<T> {
    subscribe: (callback: (msg: T) => void) => void
}

export type JsMsg =
    GotLogin
    | GotLogout
    | GotSizes
    | GotProjects
    | GotProject
    | ProjectDropped
    | GotLocalFile
    | GotRemoteFile
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
    | GotResetCanvas
    | Error
export type GotLogin = { kind: 'GotLogin', user: User }
export type GotLogout = { kind: 'GotLogout' }
export type GotSizes = { kind: 'GotSizes', sizes: ElementSize[] }
export type GotProjects = { kind: 'GotProjects', projects: [ProjectId, ProjectInfo][] }
export type GotProject = { kind: 'GotProject', project: Project }
export type ProjectDropped = { kind: 'ProjectDropped', id: ProjectId }
export type GotLocalFile = { kind: 'GotLocalFile', now: Timestamp, projectId: ProjectId, sourceId: SourceId, file: File, content: string }
export type GotRemoteFile = { kind: 'GotRemoteFile', now: Timestamp, projectId: ProjectId, sourceId: SourceId, url: string, content: string, sample?: string }
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
export type GotResetCanvas = { kind: 'GotResetCanvas' }
export type Error = { kind: 'Error', message: string }

export type ElmMsg =
    ClickMsg
    | MouseDownMsg
    | FocusMsg
    | BlurMsg
    | ScrollToMsg
    | FullscreenMsg
    | SetMetaMsg
    | AutofocusWithinMsg
    | LoginMsg
    | LogoutMsg
    | ListProjectsMsg
    | LoadProjectMsg
    | LoadRemoteProjectMsg
    | CreateProjectMsg
    | UpdateProjectMsg
    | MoveProjectToMsg
    | DownloadFileMsg
    | DropProjectMsg
    | GetLocalFileMsg
    | GetRemoteFileMsg
    | ObserveSizesMsg
    | ListenKeysMsg
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
export type LoginMsg = { kind: 'Login', redirect?: string }
export type LogoutMsg = { kind: 'Logout' }
export type ListProjectsMsg = { kind: 'ListProjects' }
export type LoadProjectMsg = { kind: 'LoadProject', id: ProjectId }
export type LoadRemoteProjectMsg = { kind: 'LoadRemoteProject', projectUrl: FileUrl }
export type CreateProjectMsg = { kind: 'CreateProject', project: Project }
export type UpdateProjectMsg = { kind: 'UpdateProject', project: Project }
export type MoveProjectToMsg = { kind: 'MoveProjectTo', project: Project, storage: ProjectStorage }
export type DownloadFileMsg = { kind: 'DownloadFile', filename: FileName, content: FileContent }
export type DropProjectMsg = { kind: 'DropProject', project: ProjectInfo }
export type GetLocalFileMsg = { kind: 'GetLocalFile', project?: ProjectId, source?: SourceId, file: File }
export type GetRemoteFileMsg = { kind: 'GetRemoteFile', project?: ProjectId, source?: SourceId, url: FileUrl, sample: SampleKey }
export type ObserveSizesMsg = { kind: 'ObserveSizes', ids: HtmlId[] }
export type ListenKeysMsg = { kind: 'ListenKeys', keys: { [id: HotkeyId]: Hotkey[] } }
export type TrackPageMsg = { kind: 'TrackPage', name: string }
export type TrackEventMsg = { kind: 'TrackEvent', name: string, details: object }
export type TrackErrorMsg = { kind: 'TrackError', name: string, details: object }


export type SampleKey = string

export interface ElementSize {
    id: HtmlId,
    position: Position,
    size: Size,
    seeds: Position
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
