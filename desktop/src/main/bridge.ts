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
    ipcMain.handle('columnStats', (e: IpcMainInvokeEvent, url: DatabaseUrl, column: ColumnRef) => bridge.columnStats(url, column))
}

async function ping(): Promise<string> {
    return 'pong'
}

async function databaseQuery(url: DatabaseUrl, query: string): Promise<DatabaseResults> {
    const parsedUrl = parseDatabaseUrl(url)
    if (parsedUrl.kind == 'postgres') {
        const res = await postgres.query(parsedUrl, query)
        return {rows: res.rows}
    } else {
        return Promise.reject(`Unsupported '${parsedUrl.kind}' database`)
    }
}

async function databaseSchema(url: DatabaseUrl): Promise<AzimuttSchema> {
    const parsedUrl = parseDatabaseUrl(url)
    console.log('parsedUrl', parsedUrl)
    if (parsedUrl.kind === 'couchbase') {
        const rawSchema: couchbase.CouchbaseSchema = await couchbase.getSchema(parsedUrl, undefined, 100, logger)
        return couchbase.formatSchema(rawSchema, 0, true)
    } else if (parsedUrl.kind === 'mongodb') {
        const rawSchema: mongodb.MongoSchema = await mongodb.getSchema(parsedUrl, undefined, 100, logger)
        return mongodb.formatSchema(rawSchema, 0, true)
    } else if (parsedUrl.kind === 'postgres') {
        const rawSchema: postgres.PostgresSchema = await postgres.getSchema(parsedUrl, undefined, 100, logger)
        return postgres.formatSchema(rawSchema, 0, true)
    } else {
        return Promise.reject(`Database '${parsedUrl.kind}' is not supported`)
    }
}

async function tableStats(url: DatabaseUrl, table: TableId): Promise<TableStats> {
    return Promise.reject('Not implemented')
}

async function columnStats(url: DatabaseUrl, column: ColumnRef): Promise<ColumnStats> {
    return Promise.reject('Not implemented')
}
