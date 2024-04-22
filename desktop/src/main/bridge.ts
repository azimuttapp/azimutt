import {ipcMain, IpcMainInvokeEvent} from "electron";
import {
    AttributeRef,
    Connector,
    ConnectorAttributeStats,
    ConnectorDefaultOpts,
    ConnectorEntityStats,
    Database,
    DatabaseQuery,
    DatabaseUrl,
    DatabaseUrlParsed,
    DesktopBridge,
    EntityRef,
    parseDatabaseUrl,
    QueryAnalyze,
    QueryResults
} from "@azimutt/models";
import {postgres} from "@azimutt/connector-postgres";
import {logger} from "./logger";

/* eslint @typescript-eslint/no-explicit-any: 0 */
export const setupBridge = (): void => {
    // define a bridge object to benefit from TS typing, but don't forget to put these functions in `ipcMain.handle`
    const bridge: DesktopBridge = {
        versions: {node: (): string => "", chrome: (): string => "", electron: (): string => ""},
        ping: ping,
        getSchema: (url: DatabaseUrl): Promise<Database> =>
            withConnector(url, (conn, parsedUrl) => conn.getSchema(application, parsedUrl, {...opts, inferRelations: true, ignoreErrors: true})),
        getQueryHistory: (url: DatabaseUrl): Promise<DatabaseQuery[]> =>
            withConnector(url, (conn, parsedUrl) => conn.getQueryHistory(application, parsedUrl, opts)),
        execute: (url: DatabaseUrl, query: string, parameters: any[]): Promise<QueryResults> =>
            withConnector(url, (conn, parsedUrl) => conn.execute(application, parsedUrl, query, parameters, opts)),
        analyze: (url: DatabaseUrl, query: string, parameters: any[]): Promise<QueryAnalyze> =>
            withConnector(url, (conn, parsedUrl) => conn.analyze(application, parsedUrl, query, parameters, opts)),
        getEntityStats: (url: DatabaseUrl, ref: EntityRef): Promise<ConnectorEntityStats> =>
            withConnector(url, (conn, parsedUrl) => conn.getEntityStats(application, parsedUrl, ref, opts)),
        getAttributeStats: (url: DatabaseUrl, ref: AttributeRef): Promise<ConnectorAttributeStats> =>
            withConnector(url, (conn, parsedUrl) => conn.getAttributeStats(application, parsedUrl, ref, opts)),
    }
    ipcMain.handle('ping', () => bridge.ping())
    ipcMain.handle('getSchema', (e: IpcMainInvokeEvent, url: DatabaseUrl) => bridge.getSchema(url))
    ipcMain.handle('getQueryHistory', (e: IpcMainInvokeEvent, url: DatabaseUrl) => bridge.getQueryHistory(url))
    ipcMain.handle('execute', (e: IpcMainInvokeEvent, url: DatabaseUrl, query: string, parameters: any[]) => bridge.execute(url, query, parameters))
    ipcMain.handle('analyze', (e: IpcMainInvokeEvent, url: DatabaseUrl, query: string, parameters: any[]) => bridge.analyze(url, query, parameters))
    ipcMain.handle('getEntityStats', (e: IpcMainInvokeEvent, url: DatabaseUrl, ref: EntityRef) => bridge.getEntityStats(url, ref))
    ipcMain.handle('getAttributeStats', (e: IpcMainInvokeEvent, url: DatabaseUrl, ref: AttributeRef) => bridge.getAttributeStats(url, ref))
}
/* eslint @typescript-eslint/no-explicit-any: 2 */

const application = 'azimutt-desktop'
const opts: ConnectorDefaultOpts = {logger}

async function ping(): Promise<string> {
    return 'pong'
}

function withConnector<T>(url: DatabaseUrl, exec: (conn: Connector, parsedUrl: DatabaseUrlParsed) => Promise<T>): Promise<T> {
    // FIXME: got error: "Error: Could not locate the bindings file." :(
    const parsedUrl = parseDatabaseUrl(url)
    /* if (parsedUrl.kind === 'couchbase') {
        return exec(parsedUrl, couchbase)
    } else if (parsedUrl.kind === 'mongodb') {
        return exec(parsedUrl, mongodb)
    } else */ if (parsedUrl.kind === 'postgres') {
        return exec(postgres, parsedUrl)
    } else {
        return Promise.reject(`Not supported database: '${parsedUrl.kind || url}'`)
    }
}
