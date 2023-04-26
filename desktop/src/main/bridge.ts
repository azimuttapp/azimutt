import {ipcMain, IpcMainInvokeEvent} from "electron"
import {DatabaseUrl, QueryResults} from "../shared";
import {DbUrl, parseUrl} from "./database-url";
import * as Postgres from "./postgres";

export const setupBridge = (): void => {
    ipcMain.handle('ping', () => {
        console.log('ping')
        return 'pong'
    })
    ipcMain.handle('databaseQuery', (e: IpcMainInvokeEvent, url: DatabaseUrl, query: string): Promise<QueryResults> => {
        console.log('databaseQuery', url, query)
        const parsedUrl: DbUrl = parseUrl(url)
        if (parsedUrl.kind == 'postgres') {
            return Postgres.query(parsedUrl, query).then(res => {
                return {rows: res.rows}
            })
        } else {
            return Promise.reject(`Unsupported '${parsedUrl.kind}' database`)
        }
    })
}
