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
        databaseQuery: databaseQuery,
        databaseSchema: databaseSchema,
        tableStats: tableStats,
        columnStats: columnStats
    }
    ipcMain.handle('ping', (e: IpcMainInvokeEvent) => bridge.ping())
    ipcMain.handle('databaseQuery', (e: IpcMainInvokeEvent, url: DatabaseUrl, query: string) => bridge.databaseQuery(url, query))
    ipcMain.handle('databaseSchema', (e: IpcMainInvokeEvent, url: DatabaseUrl) => bridge.databaseSchema(url))
    ipcMain.handle('tableStats', (e: IpcMainInvokeEvent, url: DatabaseUrl, table: TableId) => bridge.tableStats(url, table))
    ipcMain.handle('columnStats', (e: IpcMainInvokeEvent, url: DatabaseUrl, ref: ColumnRef) => bridge.columnStats(url, ref))
}

const application = 'azimutt-desktop'

async function ping(): Promise<string> {
    return 'pong'
}

async function databaseQuery(url: DatabaseUrl, query: string): Promise<DatabaseResults> {
    const parsedUrl = parseDatabaseUrl(url)
    if (parsedUrl.kind == 'postgres') {
        const res = await postgres.query(application, parsedUrl, query)
        return {rows: res.rows}
    } else {
        return Promise.reject(`databaseQuery is not supported for '${parsedUrl.kind || url}'`)
    }
}

async function databaseSchema(url: DatabaseUrl): Promise<AzimuttSchema> {
    const parsedUrl = parseDatabaseUrl(url)
    if (parsedUrl.kind === 'couchbase') {
        const rawSchema: couchbase.CouchbaseSchema = await couchbase.getSchema(application, parsedUrl, undefined, 100, logger)
        return couchbase.formatSchema(rawSchema, 0, true)
    } else if (parsedUrl.kind === 'mongodb') {
        const rawSchema: mongodb.MongoSchema = await mongodb.getSchema(application, parsedUrl, undefined, 100, logger)
        return mongodb.formatSchema(rawSchema, 0, true)
    } else if (parsedUrl.kind === 'postgres') {
        const rawSchema: postgres.PostgresSchema = await postgres.getSchema(application, parsedUrl, undefined, 100, logger)
        return postgres.formatSchema(rawSchema, 0, true)
    } else {
        return Promise.reject(`databaseSchema is not supported for '${parsedUrl.kind || url}'`)
    }
}

async function tableStats(url: DatabaseUrl, table: TableId): Promise<TableStats> {
    const parsedUrl = parseDatabaseUrl(url)
    if (parsedUrl.kind === 'postgres') {
        return postgres.tableStats(application, parsedUrl, table)
    } else {
        return Promise.reject(`tableStats is not supported for '${parsedUrl.kind || url}'`)
    }
}

async function columnStats(url: DatabaseUrl, ref: ColumnRef): Promise<ColumnStats> {
    const parsedUrl = parseDatabaseUrl(url)
    if (parsedUrl.kind === 'postgres') {
        return postgres.columnStats(application, parsedUrl, ref)
    } else {
        return Promise.reject(`columnStats is not supported for '${parsedUrl.kind || url}'`)
    }
}
