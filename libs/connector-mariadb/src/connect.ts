import * as mariadb from "mariadb";
import {Connection, ConnectionConfig} from "mariadb";
import {DatabaseUrlParsed} from "@azimutt/database-types";
import {Conn, QueryResultArrayMode, QueryResultRow} from "./common";

export async function connect<T>(application: string, url: DatabaseUrlParsed, exec: (c: Conn) => Promise<T>): Promise<T> {
    const connection: Connection = await mariadb.createConnection(buildConfig(application, url)).catch(_ => mariadb.createConnection(url.full))
    const conn: Conn = {
        query<T extends QueryResultRow>(sql: string, parameters: any[] = []): Promise<T[]> {
            return connection.query<T[]>({sql, namedPlaceholders: true}, parameters)
        },
        queryArrayMode(sql: string, parameters: any[] = []): Promise<QueryResultArrayMode> {
            return connection.query({sql, namedPlaceholders: true, rowsAsArray: true}, parameters)
                .then(([rows, fields]) => ({fields, rows}))
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
