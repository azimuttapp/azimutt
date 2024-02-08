import {Connection, ConnectionOptions, SnowflakeError, Statement} from "snowflake-sdk";
import * as snowflake from "snowflake-sdk";
import {DatabaseUrlParsed} from "@azimutt/database-types";
import {Conn, QueryResultArrayMode, QueryResultRow} from "./common";

export async function connect<T>(application: string, url: DatabaseUrlParsed, exec: (c: Conn) => Promise<T>): Promise<T> {
    const connection: Connection = await createConnection(buildConfig(application, url))
        .catch(_ => createConnection({application, accessUrl: url.full, account: 'not used'}))
    const conn: Conn = {
        query<T extends QueryResultRow>(sql: string, parameters: any[] = []): Promise<T[]> {
            return new Promise<T[]>((resolve, reject) => connection.execute({
                sqlText: sql,
                binds: parameters,
                complete: (err: SnowflakeError | undefined, stmt: Statement, rows: any[] | undefined) =>
                    err ? reject(queryError(sql, err)) : resolve(rows || [] as T[])
            }))
        },
        queryArrayMode(sql: string, parameters: any[] = []): Promise<QueryResultArrayMode> {
            return new Promise<QueryResultArrayMode>((resolve, reject) => connection.execute({
                sqlText: sql,
                binds: parameters,
                // @ts-ignore
                rowMode: 'array',
                complete: (err: SnowflakeError | undefined, stmt: Statement, rows: any[] | undefined) => err ? reject(queryError(sql, err)) : resolve({
                    fields: stmt.getColumns().map(c => ({ name: c.getName(), tableID: 0, columnID: c.getId(), dataTypeID: 0, format: c.getType() })),
                    rows: rows || []
                })
            }))
        }
    }
    return exec(conn).then(
        res => closeConnection(connection).then(_ => res),
        err => closeConnection(connection).then(_ => Promise.reject(err))
    )
}

async function createConnection(options: ConnectionOptions): Promise<Connection> {
    try {
        const connection: Connection = snowflake.createConnection(options)
        return new Promise((resolve, reject) =>
            connection.connect((err: SnowflakeError | undefined, conn: Connection) =>
                err ? reject(err) : resolve(conn)
            )
        )
    } catch (e) {
        return Promise.reject(e)
    }
}

async function closeConnection(connection: Connection): Promise<void> {
    return new Promise((resolve, reject) =>
        connection.destroy((err: SnowflakeError | undefined) =>
            err ? reject(err) : resolve()
        )
    )
}

function buildConfig(application: string, url: DatabaseUrlParsed): ConnectionOptions {
    const opts = Object.fromEntries((url.options || '').split('&').map(part => part.split('=')))
    return {
        application: application,
        account: (url.host || 'missing').replace(/(\.privatelink)?\.snowflakecomputing\.com$/, ''),
        username: url.user,
        password: url.pass,
        database: url.db,
        schema: opts['schema'],
        warehouse: opts['warehouse'],
    }
}

function queryError(sql: string, err: unknown): Error {
    if (typeof err === 'object' && err !== null) {
        return new Error(`${err.constructor.name}${'code' in err ? ` ${err.code}` : ''}${'message' in err ? `:\n ${err.message}` : ''}\n on '${sql}'`)
    } else if (err) {
        return new Error(`error ${JSON.stringify(err)}\n on '${sql}'`)
    } else {
        return new Error(`error on '${sql}'`)
    }
}
