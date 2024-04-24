import * as mysql from "mysql2/promise";
import {Connection, ConnectionOptions, RowDataPacket} from "mysql2/promise";
import {AnyError} from "@azimutt/utils";
import {
    AttributeValue,
    ConnectorDefaultOpts,
    DatabaseUrlParsed,
    logQueryIfNeeded,
    queryError
} from "@azimutt/models";

export async function connect<T>(application: string, url: DatabaseUrlParsed, exec: (c: Conn) => Promise<T>, opts: ConnectorDefaultOpts): Promise<T> {
    const connection: Connection = await mysql.createConnection(buildConfig(application, url))
        .catch(_ => mysql.createConnection({uri: url.full}))
        .catch(err => Promise.reject(connectionError(err)))
    let queryCpt = 1
    const conn: Conn = {
        url,
        query<T extends QueryResultRow>(sql: string, parameters: any[] = [], name?: string): Promise<T[]> {
            return logQueryIfNeeded(queryCpt++, name, sql, parameters, (sql, parameters) => {
                return connection.query<RowDataPacket[]>({sql, values: parameters})
                    .then(([rows]) => rows as T[], err => Promise.reject(queryError(name, sql, err)))
            }, r => r.length, opts)
        },
        queryArrayMode(sql: string, parameters: any[] = [], name?: string): Promise<QueryResultArrayMode> {
            return logQueryIfNeeded(queryCpt++, name, sql, parameters, (sql, parameters) => {
                return connection.query<RowDataPacket[][]>({sql, values: parameters, rowsAsArray: true})
                    .then(([rows, fields]) => ({fields, rows}), err => Promise.reject(queryError(name, sql, err)))
            }, r => r.rows.length, opts)
        }
    }
    return exec(conn).then(
        res => connection.end().then(_ => res),
        err => connection.end().then(_ => Promise.reject(err))
    )
}

export interface Conn {
    url: DatabaseUrlParsed

    query<T extends QueryResultRow>(sql: string, parameters?: any[], name?: string): Promise<T[]>

    queryArrayMode(sql: string, parameters?: any[], name?: string): Promise<QueryResultArrayMode>
}

export type QueryResultValue = AttributeValue
export type QueryResultRow = { [column: string]: QueryResultValue }
export type QueryResultField = { name: string }
export type QueryResultRowArray = QueryResultValue[]
export type QueryResultArrayMode = {
    fields: QueryResultField[],
    rows: QueryResultRowArray[]
}

function buildConfig(application: string, url: DatabaseUrlParsed): ConnectionOptions {
    return {
        host: url.host,
        port: url.port,
        user: url.user,
        password: url.pass,
        database: url.db,
        insecureAuth: true
        // ssl
    }
}

function connectionError(err: AnyError): AnyError {
    // TODO: improve error messages here if needed
    return err
}
