import mysql, {Connection, RowDataPacket} from "mysql2/promise";
import {DatabaseUrlParsed} from "@azimutt/database-types";

export async function connect<T>(application: string, url: DatabaseUrlParsed, exec: (c: Connection) => Promise<T>): Promise<T> {
    const connection: Connection = await mysql.createConnection({
        host: url.host,
        port: url.port,
        user: url.user,
        password: url.pass,
        database: url.db,
        insecureAuth: true
    })
    return exec(connection)
        .then(res => connection.end().then(_ => res))
        .catch(err => connection.end().then(_ => Promise.reject(err)))
}

export async function query<T>(conn: Connection, sql: string, parameters: any[] = []): Promise<T[]> {
    return conn.query<RowDataPacket[]>({sql, values: parameters}).then(([rows]) => rows as T[])
}
