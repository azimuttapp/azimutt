import os from "os";
import fs from "fs";
import process from "process";
import {BigQuery} from "@google-cloud/bigquery";
import {SimpleQueryRowsResponse} from "@google-cloud/bigquery/build/src/bigquery";
import {AnyError} from "@azimutt/utils";
import {
    AttributeValue,
    ConnectorDefaultOpts,
    DatabaseUrlParsed,
    logQueryIfNeeded,
    queryError
} from "@azimutt/database-model";

export type QueryResultRow = { [column: string]: AttributeValue }
export interface Conn {
    underlying: BigQuery
    query<T extends QueryResultRow>(sql: string, parameters?: any[], name?: string): Promise<T[]>
}

export async function connect<T>(application: string, url: DatabaseUrlParsed, exec: (c: Conn) => Promise<T>, opts: ConnectorDefaultOpts): Promise<T> {
    if (!url.pass) return Promise.reject(new Error(`Missing key file, add 'key' param to your url with the path to the file, ex: '?key=path/to/key.json'.`))
    const keyPath = url.pass.startsWith('~') ? url.pass.replace(/^~/, os.homedir()) : url.pass
    if (!fs.existsSync(keyPath)) return Promise.reject(new Error(`Key file '${url.pass}' not found in '${process.cwd()}', make sure the 'key' url param has the correct path.`))
    const client: BigQuery = new BigQuery({
        apiEndpoint: url.host,
        projectId: url.db,
        keyFilename: keyPath
    })
    await client.query('SELECT 1') // make sure the connection is working
        .catch(err => Promise.reject(connectionError(err)))
    let queryCpt = 1
    const conn: Conn = {
        underlying: client,
        query<T extends QueryResultRow>(sql: string, parameters: any[] = [], name?: string): Promise<T[]> {
            return logQueryIfNeeded(queryCpt++, name, sql, parameters, (sql, parameters) => {
                return client.query({query: sql, params: parameters}).then(([rows]: SimpleQueryRowsResponse) => rows as T[], err => Promise.reject(queryError(name, sql, err)))
            }, r => r.length, opts)
        }
    }
    return exec(conn)
}

function connectionError(err: AnyError): AnyError {
    // TODO: improve error messages here if needed
    return err
}
