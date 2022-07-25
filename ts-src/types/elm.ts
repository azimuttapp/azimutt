import {
    Email,
    Env,
    File,
    FileContent,
    FileName,
    FileUrl,
    HtmlId,
    Platform,
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
    ProjectStorage,
    Size,
    TableId
} from "./project";
import {LoginInfo} from "../services/supabase";
import {Profile, UserId} from "./profile";

export interface GlobalConf {
    env: Env
    platform: Platform
    backendUrl: string
    enableCloud: boolean
}

export interface ElmFlags {
    now: Timestamp
    conf: GlobalConf
}

export interface ElmInit {
    flags: ElmFlags
    node?: HTMLElement
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
    | GotUser
    | GotOwners
    | ProjectDropped
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
export type GotLogin = { kind: 'GotLogin', user: Profile }
export type GotLogout = { kind: 'GotLogout' }
export type GotSizes = { kind: 'GotSizes', sizes: ElementSize[] }
export type GotProjects = { kind: 'GotProjects', projects: [ProjectId, ProjectInfo][] }
export type GotProject = { kind: 'GotProject', project?: Project }
export type GotUser = { kind: 'GotUser', email: Email, user: Profile | undefined }
export type GotOwners = { kind: 'GotOwners', project: ProjectId, owners: Profile[] }
export type ProjectDropped = { kind: 'ProjectDropped', id: ProjectId }
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
    | CreateProjectMsg
    | UpdateProjectMsg
    | MoveProjectToMsg
    | GetUserMsg
    | UpdateUserMsg
    | GetOwnersMsg
    | SetOwnersMsg
    | DownloadFileMsg
    | DropProjectMsg
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
export type LoginMsg = { kind: 'Login', info: LoginInfo, redirect?: string }
export type LogoutMsg = { kind: 'Logout' }
export type ListProjectsMsg = { kind: 'ListProjects' }
export type LoadProjectMsg = { kind: 'LoadProject', id: ProjectId }
export type CreateProjectMsg = { kind: 'CreateProject', project: Project }
export type UpdateProjectMsg = { kind: 'UpdateProject', project: Project }
export type MoveProjectToMsg = { kind: 'MoveProjectTo', project: Project, storage: ProjectStorage }
export type GetUserMsg = { kind: 'GetUser', email: Email }
export type UpdateUserMsg = { kind: 'UpdateUser', user: Profile }
export type GetOwnersMsg = { kind: 'GetOwners', project: ProjectId }
export type SetOwnersMsg = { kind: 'SetOwners', project: ProjectId, owners: UserId[] }
export type DownloadFileMsg = { kind: 'DownloadFile', filename: FileName, content: FileContent }
export type DropProjectMsg = { kind: 'DropProject', project: ProjectInfo }
export type GetLocalFileMsg = { kind: 'GetLocalFile', sourceKind: string, file: File }
export type ObserveSizesMsg = { kind: 'ObserveSizes', ids: HtmlId[] }
export type ListenKeysMsg = { kind: 'ListenKeys', keys: { [id: HotkeyId]: Hotkey[] } }
export type ConfettiMsg = { kind: 'Confetti', id: HtmlId }
export type ConfettiPrideMsg = { kind: 'ConfettiPride' }
export type TrackPageMsg = { kind: 'TrackPage', name: string }
export type TrackEventMsg = { kind: 'TrackEvent', name: string, details?: Data }
export type TrackErrorMsg = { kind: 'TrackError', name: string, details?: Data }

// from node_modules/@splitbee/web/src/types.ts but not exported :(
export type Data = { [key: string]: string | number | boolean | undefined | null };

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
