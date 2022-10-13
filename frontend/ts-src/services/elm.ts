import {
    ElementSize,
    ElmFlags,
    ElmMsg,
    ElmRuntime,
    GetLocalFile,
    Hotkey,
    HotkeyId,
    JsMsg,
    UpdateProjectTmp
} from "../types/ports";
import {ColumnId, Project, ProjectId, ProjectInfoLocalLegacy, TableId} from "../types/project";
import {Color, Delta, Position, ToastLevel} from "../types/basics";
import {Logger} from "./logger";
import * as Zod from "../utils/zod";
import {formatError} from "../utils/error";

export class ElmApp {
    static init(flags: ElmFlags, logger: Logger) {
        return new ElmApp(window.Elm.Main.init({flags}), logger)
    }

    private callbacks: { [key in ElmMsg['kind']]: Callback<key>[] } = {
        Click: [],
        MouseDown: [],
        Focus: [],
        Blur: [],
        ScrollTo: [],
        Fullscreen: [],
        SetMeta: [],
        AutofocusWithin: [],
        Toast: [],
        GetLegacyProjects: [],
        GetProject: [],
        CreateProjectTmp: [],
        UpdateProjectTmp: [],
        CreateProject: [],
        UpdateProject: [],
        MoveProjectTo: [],
        DeleteProject: [],
        DownloadFile: [],
        GetLocalFile: [],
        ObserveSizes: [],
        ListenKeys: [],
        TrackPage: [],
        Confetti: [],
        ConfettiPride: [],
        TrackEvent: [],
        TrackError: [],
    }

    constructor(private elm: ElmRuntime<JsMsg, ElmMsg>, private logger: Logger) {
        this.elm.ports?.elmToJs.subscribe(msg => {
            this.logger.debug('ElmMsg', msg)
            try {
                const valid: ElmMsg = Zod.validate(msg, ElmMsg, `ElmMsg[${msg.kind}]`)
                // setTimeout: a ugly hack to wait for Elm to render the model changes before running the commands :(
                // TODO: use requestAnimationFrame instead!
                setTimeout(() => {
                    const calls = this.callbacks[valid.kind]
                    if (calls.length > 0) {
                        // @ts-ignore
                        calls.map(call => call(valid))
                    } else {
                        logger.error(`Message "${valid.kind}" not handled`, valid)
                    }
                }, 100)
            } catch (e) {
                this.toast(ToastLevel.enum.error, formatError(e))
            }
        })
    }

    on = <K extends ElmMsg['kind']>(event: K, callback: (msg: ElmMsg & { kind: K }) => void): void => {
        this.callbacks[event].push(callback)
    }

    noListeners = (): ElmMsg['kind'][] => (Object.keys(this.callbacks) as ElmMsg['kind'][]).filter(c => this.callbacks[c].length === 0)

    updateSizes = (sizes: ElementSize[]): void => this.send({kind: 'GotSizes', sizes})
    gotLegacyProjects = (projects: ProjectInfoLocalLegacy[]): void => this.send({
        kind: 'GotLegacyProjects',
        projects: projects.map(p => [p.id, p])
    })
    gotProject = (project: Project | undefined): void => {
        window.azimutt.project = project
        project ? this.send({kind: 'GotProject', project}) : this.send({kind: 'GotProject'})
    }
    dropProject = (id: ProjectId): void => this.send({kind: 'ProjectDeleted', id})
    gotLocalFile = (msg: GetLocalFile, content: string): void => this.send({
        kind: 'GotLocalFile',
        sourceKind: msg.sourceKind,
        file: msg.file,
        content
    })
    gotHotkey = (hotkey: Hotkey & { id: HotkeyId }): void => this.send({kind: 'GotHotkey', id: hotkey.id})
    gotKeyHold = (key: string, start: boolean): void => this.send({kind: 'GotKeyHold', key, start})
    toast = (level: ToastLevel, message: string): void => this.send({kind: 'GotToast', level, message})
    showTable = (id: TableId, position?: Position): void => this.send({kind: 'GotTableShow', id, position})
    hideTable = (id: TableId): void => this.send({kind: 'GotTableHide', id})
    toggleTableColumns = (id: TableId): void => this.send({kind: 'GotTableToggleColumns', id})
    setTablePosition = (id: TableId, position: Position): void => this.send({kind: 'GotTablePosition', id, position})
    moveTable = (id: TableId, delta: Delta): void => this.send({kind: 'GotTableMove', id, delta})
    selectTable = (id: TableId): void => this.send({kind: 'GotTableSelect', id})
    setTableColor = (id: TableId, color: Color): void => this.send({kind: 'GotTableColor', id, color})
    showColumn = (id: ColumnId): void => this.send({kind: 'GotColumnShow', ref: id})
    hideColumn = (id: ColumnId): void => this.send({kind: 'GotColumnHide', ref: id})
    moveColumn = (id: ColumnId, index: number): void => this.send({kind: 'GotColumnMove', ref: id, index})
    fitToScreen = (): void => this.send({kind: 'GotFitToScreen'})

    private send(msg: JsMsg): void {
        this.logger.debug('JsMsg', msg)
        try {
            const valid: JsMsg = Zod.validate(msg, JsMsg, `JsMsg[${msg.kind}]`)
            this.elm.ports?.jsToElm.send(valid)
        } catch (e) {
            this.toast(ToastLevel.enum.error, formatError(e))
        }
    }
}

type Callback<key> = (msg: ElmMsg & { kind: key }) => void
