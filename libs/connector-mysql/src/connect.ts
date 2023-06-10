import mysql, {Connection, RowDataPacket} from "mysql2/promise";
import {DatabaseUrlParsed} from "@azimutt/database-types";
import {Conn, QueryResultArrayMode, QueryResultRow} from "./common";

export async function connect<T>(application: string, url: DatabaseUrlParsed, exec: (c: Conn) => Promise<T>): Promise<T> {
    const connection: Connection = await mysql.createConnection({
        host: url.host,
        port: url.port,
        user: url.user,
        password: url.pass,
        database: url.db,
        insecureAuth: true
    })
    const conn: Conn = {
        query<T extends QueryResultRow>(sql: string, parameters: any[] = []): Promise<T[]> {
            return connection.query<RowDataPacket[]>({sql, values: parameters}).then(([rows]) => rows as T[])
        },
        queryArrayMode(sql: string, parameters: any[] = []): Promise<QueryResultArrayMode> {
            return connection.query<RowDataPacket[][]>({sql, values: parameters, rowsAsArray: true})
                .then(([rows, fields]) => ({fields, rows}))
        }
    }
    return exec(conn)
        .then(res => connection.end().then(_ => res))
        .catch(err => connection.end().then(_ => Promise.reject(err)))
}
