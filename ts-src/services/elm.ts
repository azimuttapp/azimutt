import {
    ElementSize,
    ElmFlags,
    ElmMsg,
    ElmRuntime,
    GetLocalFileMsg,
    GetRemoteFileMsg,
    Hotkey,
    HotkeyId,
    JsMsg
} from "../types/elm";
import {Color, ColumnId, Delta, Position, Project, TableId} from "../types/project";
import {ToastLevel} from "../types/basics";
import {randomUID} from "../utils";
import {Logger} from "./logger";

type Callback<key> = (msg: ElmMsg & { kind: key }) => void

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
        LoadProjects: [],
        LoadRemoteProject: [],
        SaveProject: [],
        DownloadFile: [],
        DropProject: [],
        GetLocalFile: [],
        GetRemoteFile: [],
        ObserveSizes: [],
        ListenKeys: [],
        TrackPage: [],
        TrackEvent: [],
        TrackError: [],
    }

    constructor(private elm: ElmRuntime, private logger: Logger) {
        this.elm.ports?.elmToJs.subscribe(msg => {
            // setTimeout: a ugly hack to wait for Elm to render the model changes before running the commands :(
            // TODO: use requestAnimationFrame instead!
            setTimeout(() => {
                const calls = this.callbacks[msg.kind]
                if (calls.length > 0) {
                    // @ts-ignore
                    calls.map(call => call(msg))
                } else {
                    logger.error(`Message "${msg.kind}" not handled`, msg)
                }
            }, 100)
        })
    }

    on = <K extends ElmMsg['kind']>(event: K, callback: (msg: ElmMsg & { kind: K }) => void): void => {
        this.callbacks[event].push(callback)
    }

    noListeners = (): ElmMsg['kind'][] => (Object.keys(this.callbacks) as ElmMsg['kind'][]).filter(c => this.callbacks[c].length === 0)


    updateSizes = (sizes: ElementSize[]) => this.send({kind: 'GotSizes', sizes})
    loadProjects = (projects: Project[]): void => this.send({
        kind: 'GotProjects',
        projects: projects.map(p => [p.id, p])
    })
    gotLocalFile = (msg: GetLocalFileMsg, content: string) => this.send({
        kind: 'GotLocalFile',
        now: Date.now(),
        projectId: msg.project || randomUID(),
        sourceId: msg.source || randomUID(),
        file: msg.file,
        content
    })
    gotRemoteFile = (msg: GetRemoteFileMsg, content: string) => this.send({
        kind: 'GotRemoteFile',
        now: Date.now(),
        projectId: msg.project || randomUID(),
        sourceId: msg.source || randomUID(),
        url: msg.url,
        content,
        sample: msg.sample
    })
    gotHotkey = (hotkey: Hotkey & { id: HotkeyId }) => this.send({kind: 'GotHotkey', id: hotkey.id})
    gotKeyHold = (key: string, start: boolean) => this.send({kind: 'GotKeyHold', key, start})
    toast = (level: ToastLevel, message: string) => this.send({kind: 'GotToast', level, message})
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
    fitToScreen = () => this.send({kind: 'GotFitToScreen'})
    resetCanvas = () => this.send({kind: 'GotResetCanvas'})

    private send(msg: JsMsg): void {
        this.elm.ports?.jsToElm.send(msg)
    }
}
