import * as snowflake from "snowflake-sdk";
import {Connection, ConnectionOptions, SnowflakeError, Statement} from "snowflake-sdk";
import {AttributeValue, ConnectorDefaultOpts, DatabaseUrlParsed, logQueryIfNeeded} from "@azimutt/database-model";

export async function connect<T>(application: string, url: DatabaseUrlParsed, exec: (c: Conn) => Promise<T>, opts: ConnectorDefaultOpts): Promise<T> {
    const connection: Connection = await createConnection(buildConfig(application, url))
        .catch(_ => createConnection({application, accessUrl: url.full, account: 'not used'}))
    let queryCpt = 1
    const conn: Conn = {
        query<T extends QueryResultRow>(sql: string, parameters: any[] = [], name?: string): Promise<T[]> {
            return logQueryIfNeeded(queryCpt++, name, sql, parameters, (sql, parameters) => {
                return new Promise<T[]>((resolve, reject) => connection.execute({
                    sqlText: sql,
                    binds: parameters,
                    complete: (err: SnowflakeError | undefined, stmt: Statement, rows: any[] | undefined) =>
                        err ? reject(queryError(sql, err)) : resolve(rows || [] as T[])
                }))
            }, r => r.length, opts)
        },
        queryArrayMode(sql: string, parameters: any[] = [], name?: string): Promise<QueryResultArrayMode> {
            return logQueryIfNeeded(queryCpt++, name, sql, parameters, (sql, parameters) => {
                return new Promise<QueryResultArrayMode>((resolve, reject) => connection.execute({
                    sqlText: sql,
                    binds: parameters,
                    // @ts-ignore
                    rowMode: 'array',
                    complete: (err: SnowflakeError | undefined, stmt: Statement, rows: any[] | undefined) => err ? reject(queryError(sql, err)) : resolve({
                        fields: stmt.getColumns().map(c => ({ index: c.getIndex(), name: c.getName(), type: c.getType() })),
                        rows: rows || []
                    })
                }))
            }, r => r.rows.length, opts)
        }
    }
    return exec(conn).then(
        res => closeConnection(connection).then(_ => res),
        err => closeConnection(connection).then(_ => Promise.reject(err))
    )
}

export interface Conn {
    query<T extends QueryResultRow>(sql: string, parameters?: any[], name?: string): Promise<T[]>

    queryArrayMode(sql: string, parameters?: any[], name?: string): Promise<QueryResultArrayMode>
}

export type QueryResultValue = AttributeValue
export type QueryResultRow = { [column: string]: QueryResultValue }
export type QueryResultField = { index: number, name: string, type: string }
export type QueryResultRowArray = QueryResultValue[]
export type QueryResultArrayMode = {
    fields: QueryResultField[],
    rows: QueryResultRowArray[]
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
    const opts = Object.fromEntries((url.options || '').split('&').map(part => part.split('='))) // TODO: use parseDatabaseOptions from url.ts
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
