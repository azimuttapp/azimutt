import mysql, {Connection} from "mysql2/promise";
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
