import os from "os";
import fs from "fs";
import process from "process";
import {BigQuery} from "@google-cloud/bigquery";
import {SimpleQueryRowsResponse} from "@google-cloud/bigquery/build/src/bigquery";
import {Logger} from "@azimutt/utils";
import {ColumnValue, DatabaseUrlParsed, logQueryIfNeeded} from "@azimutt/database-types";

export type QueryResultRow = { [column: string]: ColumnValue }
export interface Conn {
    client: BigQuery
    query<T extends QueryResultRow>(sql: string, parameters?: any[], name?: string): Promise<T[]>
}

export type BigqueryConnectOpts = {logger: Logger, logQueries?: boolean}
export async function connect<T>(application: string, url: DatabaseUrlParsed, exec: (c: Conn) => Promise<T>, {logger, logQueries}: BigqueryConnectOpts): Promise<T> {
    if (!url.pass) return Promise.reject(new Error(`Missing key file, add '?key=path/to/key.json' at the end of the url`))
    const keyPath = url.pass.startsWith('~') ? url.pass.replace(/^~/, os.homedir()) : url.pass
    if (!fs.existsSync(keyPath)) return Promise.reject(new Error(`Key file '${url.pass}' not found in '${process.cwd()}'`))
    const client: BigQuery = new BigQuery({
        apiEndpoint: url.host,
        projectId: url.db,
        keyFilename: keyPath
    })
    let queryCpt = 1
    const conn: Conn = {
        client,
        query<T extends QueryResultRow>(sql: string, parameters: any[] = [], name?: string): Promise<T[]> {
            return logQueryIfNeeded(queryCpt++, name, sql, parameters, (sql, parameters) => {
                return client.query({query: sql, params: parameters}).then(([rows]: SimpleQueryRowsResponse) => rows as T[])
            }, r => r.length, logger, logQueries || false)
        }
    }
    return exec(conn)
}
