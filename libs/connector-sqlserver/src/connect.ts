import mssql, {config, ConnectionPool, IOptions, IResult, ISqlType} from "mssql";
import {Logger} from "@azimutt/utils";
import {ColumnValue, DatabaseUrlParsed} from "@azimutt/database-types";
import {Conn, QueryResultArrayMode, QueryResultRow} from "./common";

export type ConnectOpts = {logQueries: boolean, logger: Logger}
export async function connect<T>(application: string, url: DatabaseUrlParsed, exec: (c: Conn) => Promise<T>, {logQueries, logger}: ConnectOpts): Promise<T> {
    const connection: ConnectionPool = await mssql.connect(buildconfig(application, url)).catch(_ => mssql.connect(url.full))
    let queryCpt = 1
    const logQueryIfNeeded = <U>(sql: string, exec: (sql: string) => Promise<U>, count: (res: U) => number): Promise<U> => {
        // TODO: compute query time in ms
        if (logQueries) {
            const queryId = `#${queryCpt++}`
            logger.log(`${queryId} exec: ${sql}`)
            const res = exec(sql)
            res.then(
                r => logger.log(`${queryId} success: ${count(r)} rows in xx ms`),
                e => logger.log(`${queryId} failure: ${e} in xx ms`)
            )
            return res
        } else {
            return exec(sql)
        }
    }
    const conn: Conn = {
        query<T extends QueryResultRow>(sql: string, parameters: any[] = []): Promise<T[]> {
            return logQueryIfNeeded(sql, sql => {
                return connection.query<T>(sql).then(result => result.recordset)
            }, r => r.length)
        },
        queryArrayMode(sql: string, parameters: any[] = []): Promise<QueryResultArrayMode> {
            return logQueryIfNeeded(sql, async sql => {
                const request = connection.request() as any
                request.arrayRowMode = true
                const result: IResult<ColumnValue[]> & { columns: ColumnMetadata[][] } = await request.query(sql)
                return {rows: result.recordset as ColumnValue[][], fields: result.columns[0]}
            }, r => r.rows.length)
        }
    }
    return exec(conn).then(
        res => connection.close().then(_ => res),
        err => connection.close().then(_ => Promise.reject(err))
    )
}

function buildconfig(application: string, url: DatabaseUrlParsed): config {
    const props = Object.fromEntries((url.options || '').split('&').filter(o => o).map(o => o.split('=')))
    return {
        server: url.host,
        port: url.port,
        user: url.user,
        password: url.pass,
        database: url.db,
        options: {
            appName: props['app'] || application || 'azimutt',
            encrypt: ['true', 'yes'].indexOf((props['encrypt'] || '').toLowerCase()) != -1, // default: false
            trustServerCertificate: (props['trustservercertificate'] || '').toLowerCase() !== 'false', // default: true
            trustedConnection: ['true', 'yes'].indexOf((props['trusted_connection'] || '').toLowerCase()) != -1, // default: false
            // ??? MultipleActiveResultSets=False
            // ??? persist security info=True
        } as IOptions
    } as config
}

// Write missing types in @types/mssql (8.1.2 instead of 9.1.1 :/)

export type ColumnMetadata = {
    index: number;
    name: string;
    length: number;
    type: (() => ISqlType) | ISqlType;
    udt?: any;
    scale?: number | undefined;
    precision?: number | undefined;
    nullable: boolean;
    caseSensitive: boolean;
    identity: boolean;
    readOnly: boolean;
}
