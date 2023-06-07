import mssql, {ConnectionPool} from 'mssql'
import {DatabaseUrlParsed} from "@azimutt/database-types";

export async function connect<T>(application: string, url: DatabaseUrlParsed, exec: (c: ConnectionPool) => Promise<T>): Promise<T> {
    const connection: ConnectionPool = await mssql.connect(url.host ? {
        server: url.host,
        port: url.port,
        user: url.user,
        password: url.pass,
        database: url.db
    } : url.full)
    return exec(connection)
        .then(res => connection.close().then(_ => res))
        .catch(err => connection.close().then(_ => Promise.reject(err)))
}

export async function query<T>(conn: ConnectionPool, sql: string, parameters: any[] = []): Promise<T[]> {
    return conn.query<T>(sql).then(result => result.recordset)
}
