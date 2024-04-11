import {ipcMain, IpcMainInvokeEvent} from "electron";
import {
    AttributeRef,
    Connector,
    ConnectorAttributeStats,
    ConnectorDefaultOpts,
    ConnectorEntityStats,
    Database,
    DatabaseQuery,
    DatabaseUrlParsed,
    DesktopBridge,
    EntityRef,
    QueryAnalyze,
    QueryResults
} from "@azimutt/database-model";
import {postgres} from "@azimutt/connector-postgres";
import {logger} from "./logger";

export const setupBridge = (): void => {
    // define a bridge object to benefit from TS typing, but don't forget to put these functions in `ipcMain.handle`
    const bridge: DesktopBridge = {
        versions: {node: (): string => "", chrome: (): string => "", electron: (): string => ""},
        ping: ping,
        getSchema: (url: DatabaseUrlParsed): Promise<Database> =>
            withConnector(url, (conn) => conn.getSchema(application, url, {...opts, inferRelations: true, ignoreErrors: true})),
        getQueryHistory: (url: DatabaseUrlParsed): Promise<DatabaseQuery[]> =>
            withConnector(url, (conn) => conn.getQueryHistory(application, url, opts)),
        execute: (url: DatabaseUrlParsed, query: string, parameters: any[]): Promise<QueryResults> =>
            withConnector(url, (conn) => conn.execute(application, url, query, parameters, opts)),
        analyze: (url: DatabaseUrlParsed, query: string, parameters: any[]): Promise<QueryAnalyze> =>
            withConnector(url, (conn) => conn.analyze(application, url, query, parameters, opts)),
        getEntityStats: (url: DatabaseUrlParsed, ref: EntityRef): Promise<ConnectorEntityStats> =>
            withConnector(url, (conn) => conn.getEntityStats(application, url, ref, opts)),
        getAttributeStats: (url: DatabaseUrlParsed, ref: AttributeRef): Promise<ConnectorAttributeStats> =>
            withConnector(url, (conn) => conn.getAttributeStats(application, url, ref, opts)),
    }
    ipcMain.handle('ping', () => bridge.ping())
    ipcMain.handle('getSchema', (e: IpcMainInvokeEvent, url: DatabaseUrlParsed) => bridge.getSchema(url))
    ipcMain.handle('getQueryHistory', (e: IpcMainInvokeEvent, url: DatabaseUrlParsed) => bridge.getQueryHistory(url))
    ipcMain.handle('execute', (e: IpcMainInvokeEvent, url: DatabaseUrlParsed, query: string, parameters: any[]) => bridge.execute(url, query, parameters))
    ipcMain.handle('analyze', (e: IpcMainInvokeEvent, url: DatabaseUrlParsed, query: string, parameters: any[]) => bridge.analyze(url, query, parameters))
    ipcMain.handle('getEntityStats', (e: IpcMainInvokeEvent, url: DatabaseUrlParsed, ref: EntityRef) => bridge.getEntityStats(url, ref))
    ipcMain.handle('getAttributeStats', (e: IpcMainInvokeEvent, url: DatabaseUrlParsed, ref: AttributeRef) => bridge.getAttributeStats(url, ref))
}

const application = 'azimutt-desktop'
const opts: ConnectorDefaultOpts = {logger}

async function ping(): Promise<string> {
    return 'pong'
}

function withConnector<T>(url: DatabaseUrlParsed, exec: (conn: Connector) => Promise<T>): Promise<T> {
    // FIXME: got error: "Error: Could not locate the bindings file." :(
    /* if (parsedUrl.kind === 'couchbase') {
        return exec(parsedUrl, couchbase)
    } else if (parsedUrl.kind === 'mongodb') {
        return exec(parsedUrl, mongodb)
    } else */ if (url.kind === 'postgres') {
        return exec(postgres)
    } else {
        return Promise.reject(`Not supported database: '${url.kind || url}'`)
    }
}
