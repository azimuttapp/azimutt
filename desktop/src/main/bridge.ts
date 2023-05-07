import {ipcMain, IpcMainInvokeEvent} from "electron"
import {
    AzimuttSchema,
    ColumnRef,
    ColumnStats,
    DatabaseQueryResults,
    DatabaseUrl,
    parseDatabaseUrl,
    TableId,
    TableStats
} from "@azimutt/database-types";
import {DesktopBridge} from "@azimutt/shared";
// import {couchbase} from "@azimutt/connector-couchbase";
import {mongodb} from "@azimutt/connector-mongodb";
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

async function runDatabaseQuery(url: DatabaseUrl, query: string): Promise<DatabaseQueryResults> {
    const parsedUrl = parseDatabaseUrl(url)
    // FIXME: got error: "Error: Could not locate the bindings file." :(
    // Missing file: couchbase_impl, looks like the couchbase binary is not loaded in electron
    // if (parsedUrl.kind === 'couchbase') {
    //     return couchbase.query(application, parsedUrl, query, [])
    if (parsedUrl.kind == 'mongodb') {
        return mongodb.query(application, parsedUrl, query, [])
    } else if (parsedUrl.kind == 'postgres') {
        return postgres.query(application, parsedUrl, query, [])
    } else {
        return Promise.reject(`runDatabaseQuery is not supported for '${parsedUrl.kind || url}'`)
    }
}

async function getDatabaseSchema(url: DatabaseUrl): Promise<AzimuttSchema> {
    const parsedUrl = parseDatabaseUrl(url)
    // if (parsedUrl.kind === 'couchbase') {
    //     return couchbase.getSchema(application, parsedUrl, {logger, inferRelations: true})
    if (parsedUrl.kind === 'mongodb') {
        return mongodb.getSchema(application, parsedUrl, {logger, inferRelations: true})
    } else if (parsedUrl.kind === 'postgres') {
        return postgres.getSchema(application, parsedUrl, {logger, inferRelations: true})
    } else {
        return Promise.reject(`getDatabaseSchema is not supported for '${parsedUrl.kind || url}'`)
    }
}

async function getTableStats(url: DatabaseUrl, table: TableId): Promise<TableStats> {
    const parsedUrl = parseDatabaseUrl(url)
    if (parsedUrl.kind === 'postgres') {
        return postgres.getTableStats(application, parsedUrl, table)
    } else {
        return Promise.reject(`getTableStats is not supported for '${parsedUrl.kind || url}'`)
    }
}

async function getColumnStats(url: DatabaseUrl, ref: ColumnRef): Promise<ColumnStats> {
    const parsedUrl = parseDatabaseUrl(url)
    if (parsedUrl.kind === 'postgres') {
        return postgres.getColumnStats(application, parsedUrl, ref)
    } else {
        return Promise.reject(`getColumnStats is not supported for '${parsedUrl.kind || url}'`)
    }
}
