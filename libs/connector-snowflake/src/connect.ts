import * as snowflake from "snowflake-sdk";
import {Connection, ConnectionOptions, SnowflakeError, Statement} from "snowflake-sdk";
import {AnyError} from "@azimutt/utils";
import {
    AttributeValue,
    ConnectorDefaultOpts,
    DatabaseUrlParsed,
    logQueryIfNeeded,
    queryError
} from "@azimutt/models";

export async function connect<T>(application: string, url: DatabaseUrlParsed, exec: (c: Conn) => Promise<T>, opts: ConnectorDefaultOpts): Promise<T> {
    const connection: Connection = await createConnection(buildConfig(application, url))
        .catch(_ => createConnection({application, accessUrl: url.full, account: 'not used'}))
        .catch(err => Promise.reject(connectionError(err)))
    let queryCpt = 1
    const conn: Conn = {
        url,
        query<T extends QueryResultRow>(sql: string, parameters: any[] = [], name?: string): Promise<T[]> {
            return logQueryIfNeeded(queryCpt++, name, sql, parameters, (sql, parameters) => {
                return new Promise<T[]>((resolve, reject) => connection.execute({
                    sqlText: sql,
                    binds: parameters,
                    complete: (err: SnowflakeError | undefined, stmt: Statement, rows: any[] | undefined) =>
                        err ? reject(queryError(name, sql, err)) : resolve(rows || [] as T[])
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
                    complete: (err: SnowflakeError | undefined, stmt: Statement, rows: any[] | undefined) => err ? reject(queryError(name, sql, err)) : resolve({
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
    url: DatabaseUrlParsed

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
    const urlOptions = url.options || {}
    return {
        application: application,
        account: (url.host || 'missing').replace(/(\.privatelink)?\.snowflakecomputing\.com$/, ''),
        username: url.user,
        password: url.pass,
        database: url.db,
        schema: urlOptions['schema'],
        warehouse: urlOptions['warehouse'],
    }
}

function connectionError(err: AnyError): AnyError {
    // TODO: improve error messages here if needed
    return err
}
