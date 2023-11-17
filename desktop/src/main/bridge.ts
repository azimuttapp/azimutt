import {ipcMain, IpcMainInvokeEvent} from "electron"
import {
    AzimuttSchema,
    ColumnRef,
    ColumnStats,
    Connector,
    DatabaseQueryResults,
    DatabaseUrl,
    DatabaseUrlParsed,
    parseDatabaseUrl,
    TableId,
    TableStats
} from "@azimutt/database-types";
import {DesktopBridge} from "@azimutt/shared";
// import {couchbase} from "@azimutt/connector-couchbase";
// import {mongodb} from "@azimutt/connector-mongodb";
import {postgres} from "@azimutt/connector-postgres";
import {logger} from "./logger";

export const setupBridge = (): void => {
    // define a bridge object to benefit from TS typing, but don't forget to put these functions in `ipcMain.handle`
    const bridge: DesktopBridge = {
        versions: {node: (): string => "", chrome: (): string => "", electron: (): string => ""},
        ping: ping,
        getDatabaseSchema: getDatabaseSchema,
        getTableStats: getTableStats,
        getColumnStats: getColumnStats,
        runDatabaseQuery: runDatabaseQuery
    }
    ipcMain.handle('ping', () => bridge.ping())
    ipcMain.handle('getDatabaseSchema', (e: IpcMainInvokeEvent, url: DatabaseUrl) => bridge.getDatabaseSchema(url))
    ipcMain.handle('getTableStats', (e: IpcMainInvokeEvent, url: DatabaseUrl, table: TableId) => bridge.getTableStats(url, table))
    ipcMain.handle('getColumnStats', (e: IpcMainInvokeEvent, url: DatabaseUrl, ref: ColumnRef) => bridge.getColumnStats(url, ref))
    ipcMain.handle('runDatabaseQuery', (e: IpcMainInvokeEvent, url: DatabaseUrl, query: string) => bridge.runDatabaseQuery(url, query))
}

const application = 'azimutt-desktop'

async function ping(): Promise<string> {
    return 'pong'
}

async function getDatabaseSchema(url: DatabaseUrl): Promise<AzimuttSchema> {
    return withConnector(url, (parsedUrl, conn) => conn.getSchema(application, parsedUrl, {logger, inferRelations: true, ignoreErrors: true}))
}

async function runDatabaseQuery(url: DatabaseUrl, query: string): Promise<DatabaseQueryResults> {
    return withConnector(url, (parsedUrl, conn) => conn.query(application, parsedUrl, query, []))
}

async function getTableStats(url: DatabaseUrl, table: TableId): Promise<TableStats> {
    return withConnector(url, (parsedUrl, conn) => conn.getTableStats(application, parsedUrl, table))
}

async function getColumnStats(url: DatabaseUrl, ref: ColumnRef): Promise<ColumnStats> {
    return withConnector(url, (parsedUrl, conn) => conn.getColumnStats(application, parsedUrl, ref))
}

function withConnector<T>(url: DatabaseUrl, exec: (url: DatabaseUrlParsed, conn: Connector) => Promise<T>) {
    const parsedUrl = parseDatabaseUrl(url)
    // FIXME: got error: "Error: Could not locate the bindings file." :(
    /* if (parsedUrl.kind === 'couchbase') {
        return exec(parsedUrl, couchbase)
    } else if (parsedUrl.kind === 'mongodb') {
        return exec(parsedUrl, mongodb)
    } else */ if (parsedUrl.kind === 'postgres') {
        return exec(parsedUrl, postgres)
    } else {
        return Promise.reject(`Not supported database: '${parsedUrl.kind || url}'`)
    }
}
