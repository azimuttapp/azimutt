import {errorToString} from "@azimutt/utils";
import {
    Color,
    Delta,
    LegacyColumnId,
    LegacyColumnRef,
    LegacyColumnStats,
    LegacyDatabase,
    LegacyDatabaseQueryResultsColumn,
    LegacyJsValue,
    LegacyProject,
    LegacyProjectId,
    LegacySourceId,
    LegacySqlQueryOrigin,
    LegacyTableId,
    LegacyTableStats,
    Position,
    SqlStatement,
    zodParse
} from "@azimutt/models";
import {ElementSize, ElmFlags, ElmMsg, ElmRuntime, GetLocalFile, Hotkey, HotkeyId, JsMsg} from "../types/ports";
import {ToastLevel} from "../types/basics";
import {Logger} from "./logger";

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
        GetProject: [],
        CreateProjectTmp: [],
        UpdateProjectTmp: [],
        CreateProject: [],
        UpdateProject: [],
        MoveProjectTo: [],
        DeleteProject: [],
        DeleteSource: [],
        ProjectDirty: [],
        DownloadFile: [],
        CopyToClipboard: [],
        GetLocalFile: [],
        GetDatabaseSchema: [],
        GetTableStats: [],
        GetColumnStats: [],
        RunDatabaseQuery: [],
        GetPrismaSchema: [],
        ObserveSizes: [],
        LlmGenerateSql: [],
        ListenKeys: [],
        Confetti: [],
        ConfettiPride: [],
        Fireworks: [],
        Track: [],
    }

    constructor(private elm: ElmRuntime<JsMsg, ElmMsg>, private logger: Logger) {
        this.elm.ports?.elmToJs.subscribe(msg => {
            this.logger.debug('ElmMsg', msg)
            try {
                const valid: ElmMsg = zodParse(ElmMsg, `ElmMsg[${msg.kind}]`)(msg).getOrThrow()
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
                this.toast(ToastLevel.enum.error, errorToString(e))
            }
        })
    }

    on = <K extends ElmMsg['kind']>(event: K, callback: (msg: ElmMsg & { kind: K }) => void): void => {
        this.callbacks[event].push(callback)
    }

    noListeners = (): ElmMsg['kind'][] => (Object.keys(this.callbacks) as ElmMsg['kind'][]).filter(c => this.callbacks[c].length === 0)

    updateSizes = (sizes: ElementSize[]): void => this.send({kind: 'GotSizes', sizes})
    gotProject = (context: string, project: LegacyProject | undefined): void => {
        window.azimutt.project = project
        project ? this.send({kind: 'GotProject', context, project}) : this.send({kind: 'GotProject', context})
    }
    dropProject = (id: LegacyProjectId): void => this.send({kind: 'ProjectDeleted', id})
    gotLocalFile = (msg: GetLocalFile, content: string): void => this.send({
        kind: 'GotLocalFile',
        sourceKind: msg.sourceKind,
        file: msg.file,
        content
    })
    gotDatabaseSchema = (schema: LegacyDatabase): void => this.send({kind: 'GotDatabaseSchema', schema})
    gotDatabaseSchemaError = (error: string): void => this.send({kind: 'GotDatabaseSchemaError', error})
    gotTableStats = (source: LegacySourceId, stats: LegacyTableStats): void => this.send({kind: 'GotTableStats', source, stats})
    gotTableStatsError = (source: LegacySourceId, table: LegacyTableId, error: string): void => this.send({kind: 'GotTableStatsError', source, table, error})
    gotColumnStats = (source: LegacySourceId, stats: LegacyColumnStats): void => this.send({kind: 'GotColumnStats', source, stats})
    gotColumnStatsError = (source: LegacySourceId, column: LegacyColumnRef, error: string): void => this.send({kind: 'GotColumnStatsError', source, column, error})
    gotDatabaseQueryResult = (context: string, query: LegacySqlQueryOrigin, result: string | {columns: LegacyDatabaseQueryResultsColumn[], rows: LegacyJsValue[]}, started: number, finished: number): void => this.send({kind: 'GotDatabaseQueryResult', context, query, result, started, finished})
    gotPrismaSchema = (schema: LegacyDatabase): void => this.send({kind: 'GotPrismaSchema', schema})
    gotPrismaSchemaError = (error: string): void => this.send({kind: 'GotPrismaSchemaError', error})
    gotHotkey = (hotkey: Hotkey & { id: HotkeyId }): void => this.send({kind: 'GotHotkey', id: hotkey.id})
    gotKeyHold = (key: string, start: boolean): void => this.send({kind: 'GotKeyHold', key, start})
    toast = (level: ToastLevel, message: string): void => this.send({kind: 'GotToast', level, message})
    showTable = (id: LegacyTableId, position?: Position): void => this.send({kind: 'GotTableShow', id, position})
    hideTable = (id: LegacyTableId): void => this.send({kind: 'GotTableHide', id})
    toggleTableColumns = (id: LegacyTableId): void => this.send({kind: 'GotTableToggleColumns', id})
    setTablePosition = (id: LegacyTableId, position: Position): void => this.send({kind: 'GotTablePosition', id, position})
    moveTable = (id: LegacyTableId, delta: Delta): void => this.send({kind: 'GotTableMove', id, delta})
    selectTable = (id: LegacyTableId): void => this.send({kind: 'GotTableSelect', id})
    setTableColor = (id: LegacyTableId, color: Color): void => this.send({kind: 'GotTableColor', id, color})
    showColumn = (id: LegacyColumnId): void => this.send({kind: 'GotColumnShow', ref: id})
    hideColumn = (id: LegacyColumnId): void => this.send({kind: 'GotColumnHide', ref: id})
    moveColumn = (id: LegacyColumnId, index: number): void => this.send({kind: 'GotColumnMove', ref: id, index})
    fitToScreen = (): void => this.send({kind: 'GotFitToScreen'})
    gotLlmSqlGenerated = (query: SqlStatement): void => this.send({kind: 'GotLlmSqlGenerated', query})
    gotLlmSqlGeneratedError = (error: string): void => this.send({kind: 'GotLlmSqlGeneratedError', error})

    private send(msg: JsMsg): void {
        this.logger.debug('JsMsg', msg)
        try {
            const valid: JsMsg = zodParse(JsMsg, `JsMsg[${msg.kind}]`)(msg).getOrThrow()
            this.elm.ports?.jsToElm.send(valid)
        } catch (e) {
            this.toast(ToastLevel.enum.error, errorToString(e))
        }
    }
}

type Callback<key> = (msg: ElmMsg & { kind: key }) => void
