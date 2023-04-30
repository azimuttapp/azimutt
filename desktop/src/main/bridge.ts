import {ipcMain, IpcMainInvokeEvent} from "electron"
import {
    AzimuttSchema,
    ColumnRef,
    ColumnStats,
    DatabaseResults,
    DatabaseUrl,
    parseDatabaseUrl,
    TableId,
    TableStats
} from "@azimutt/database-types";
import {DesktopBridge} from "@azimutt/shared";
import * as couchbase from "@azimutt/connector-couchbase";
import * as mongodb from "@azimutt/connector-mongodb";
import * as postgres from "@azimutt/connector-postgres";
import {logger} from "./logger";

export const setupBridge = (): void => {
    // define a bridge object to benefit from TS typing, but don't forget to put these functions in `ipcMain.handle`
    const bridge: DesktopBridge = {
        versions: {node: (): string => "", chrome: (): string => "", electron: (): string => ""},
        ping: ping,
        queryDatabase: queryDatabase,
        getDatabaseSchema: getDatabaseSchema,
        getTableStats: getTableStats,
        getColumnStats: getColumnStats
    }
    ipcMain.handle('ping', (e: IpcMainInvokeEvent) => bridge.ping())
    ipcMain.handle('queryDatabase', (e: IpcMainInvokeEvent, url: DatabaseUrl, query: string) => bridge.queryDatabase(url, query))
    ipcMain.handle('getDatabaseSchema', (e: IpcMainInvokeEvent, url: DatabaseUrl) => bridge.getDatabaseSchema(url))
    ipcMain.handle('getTableStats', (e: IpcMainInvokeEvent, url: DatabaseUrl, table: TableId) => bridge.getTableStats(url, table))
    ipcMain.handle('getColumnStats', (e: IpcMainInvokeEvent, url: DatabaseUrl, ref: ColumnRef) => bridge.getColumnStats(url, ref))
}

const application = 'azimutt-desktop'

async function ping(): Promise<string> {
    return 'pong'
}

async function queryDatabase(url: DatabaseUrl, query: string): Promise<DatabaseResults> {
    const parsedUrl = parseDatabaseUrl(url)
    if (parsedUrl.kind == 'postgres') {
        const res = await postgres.query(application, parsedUrl, query)
        return {rows: res.rows}
    } else {
        return Promise.reject(`queryDatabase is not supported for '${parsedUrl.kind || url}'`)
    }
}

async function getDatabaseSchema(url: DatabaseUrl): Promise<AzimuttSchema> {
    const parsedUrl = parseDatabaseUrl(url)
    // FIXME: got error: "Error: Could not locate the bindings file." :(
    // Missing file: couchbase_impl, looks like the couchbase binary is not loaded in electron
    // if (parsedUrl.kind === 'couchbase') {
    //     const rawSchema: couchbase.CouchbaseSchema = await couchbase.getSchema(application, parsedUrl, undefined, 100, logger)
    //     return couchbase.formatSchema(rawSchema, 0, true)
    if (parsedUrl.kind === 'mongodb') {
        const rawSchema: mongodb.MongoSchema = await mongodb.getSchema(application, parsedUrl, undefined, 100, logger)
        return mongodb.formatSchema(rawSchema, 0, true)
    } else if (parsedUrl.kind === 'postgres') {
        const rawSchema: postgres.PostgresSchema = await postgres.getSchema(application, parsedUrl, undefined, 100, logger)
        return postgres.formatSchema(rawSchema, 0, true)
    } else {
        return Promise.reject(`getDatabaseSchema is not supported for '${parsedUrl.kind || url}'`)
    }
}

async function getTableStats(url: DatabaseUrl, table: TableId): Promise<TableStats> {
    const parsedUrl = parseDatabaseUrl(url)
    if (parsedUrl.kind === 'postgres') {
        return postgres.tableStats(application, parsedUrl, table)
    } else {
        return Promise.reject(`getTableStats is not supported for '${parsedUrl.kind || url}'`)
    }
}

async function getColumnStats(url: DatabaseUrl, ref: ColumnRef): Promise<ColumnStats> {
    const parsedUrl = parseDatabaseUrl(url)
    if (parsedUrl.kind === 'postgres') {
        return postgres.columnStats(application, parsedUrl, ref)
    } else {
        return Promise.reject(`getColumnStats is not supported for '${parsedUrl.kind || url}'`)
    }
}
