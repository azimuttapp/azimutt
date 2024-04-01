import os from "os";
import fs from "fs";
import process from "process";
import {BigQuery} from "@google-cloud/bigquery";
import {SimpleQueryRowsResponse} from "@google-cloud/bigquery/build/src/bigquery";
import {AttributeValue, ConnectorDefaultOpts, DatabaseUrlParsed, logQueryIfNeeded} from "@azimutt/database-model";

export type QueryResultRow = { [column: string]: AttributeValue }
export interface Conn {
    underlying: BigQuery
    query<T extends QueryResultRow>(sql: string, parameters?: any[], name?: string): Promise<T[]>
}

export async function connect<T>(application: string, url: DatabaseUrlParsed, exec: (c: Conn) => Promise<T>, opts: ConnectorDefaultOpts): Promise<T> {
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
        underlying: client,
        query<T extends QueryResultRow>(sql: string, parameters: any[] = [], name?: string): Promise<T[]> {
            return logQueryIfNeeded(queryCpt++, name, sql, parameters, (sql, parameters) => {
                return client.query({query: sql, params: parameters}).then(([rows]: SimpleQueryRowsResponse) => rows as T[])
            }, r => r.length, opts)
        }
    }
    return exec(conn)
}
