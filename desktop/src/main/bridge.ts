import {ipcMain, IpcMainInvokeEvent} from "electron"
import {DatabaseResults, DatabaseUrl, parseDatabaseUrl} from "@azimutt/database-types";
import * as Postgres from "@azimutt/connector-postgres";

export const setupBridge = (): void => {
    ipcMain.handle('ping', () => {
        console.log('ping')
        return 'pong'
    })
    ipcMain.handle('databaseQuery', (e: IpcMainInvokeEvent, url: DatabaseUrl, query: string): Promise<DatabaseResults> => {
        console.log('databaseQuery', url, query)
        const parsedUrl = parseDatabaseUrl(url)
        if (parsedUrl.kind == 'postgres') {
            return Postgres.query(parsedUrl, query).then(res => {
                return {rows: res.rows}
            })
        } else {
            return Promise.reject(`Unsupported '${parsedUrl.kind}' database`)
        }
    })
}
