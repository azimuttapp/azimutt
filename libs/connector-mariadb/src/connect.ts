import * as mariadb from "mariadb";
import {Connection, ConnectionConfig} from "mariadb";
import {ConnectorDefaultOpts, DatabaseUrlParsed, logQueryIfNeeded} from "@azimutt/database-model";
import {Conn, QueryResultArrayMode, QueryResultRow} from "./common";

export async function connect<T>(application: string, url: DatabaseUrlParsed, exec: (c: Conn) => Promise<T>, opts: ConnectorDefaultOpts): Promise<T> {
    const connection: Connection = await mariadb.createConnection(buildConfig(application, url)).catch(_ => mariadb.createConnection(url.full))
    let queryCpt = 1
    const conn: Conn = {
        query<T extends QueryResultRow>(sql: string, parameters: any[] = [], name?: string): Promise<T[]> {
            return logQueryIfNeeded(queryCpt++, name, sql, parameters, (sql, parameters) => {
                return connection.query<T[]>({sql, namedPlaceholders: true}, parameters)
            }, r => r.length, opts)
        },
        queryArrayMode(sql: string, parameters: any[] = [], name?: string): Promise<QueryResultArrayMode> {
            return logQueryIfNeeded(queryCpt++, name, sql, parameters, (sql, parameters) => {
                return connection.query({sql, namedPlaceholders: true, rowsAsArray: true}, parameters)
                    .then(([rows, fields]) => ({fields, rows}))
            }, r => r.rows.length, opts)
        }
    }
    return exec(conn).then(
        res => connection.end().then(_ => res),
        err => connection.end().then(_ => Promise.reject(err))
    )
}

function buildConfig(application: string, url: DatabaseUrlParsed): ConnectionConfig {
    return {
        host: url.host,
        port: url.port,
        user: url.user,
        password: url.pass,
        database: url.db
        // ssl
    }
}
