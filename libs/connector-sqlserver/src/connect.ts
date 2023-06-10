import mssql, {ConnectionPool, IResult, ISqlType} from "mssql";
import {ColumnValue, DatabaseUrlParsed} from "@azimutt/database-types";
import {Conn, QueryResultArrayMode, QueryResultRow} from "./common";

export async function connect<T>(application: string, url: DatabaseUrlParsed, exec: (c: Conn) => Promise<T>): Promise<T> {
    const connection: ConnectionPool = await mssql.connect(url.host ? {
        server: url.host,
        port: url.port,
        user: url.user,
        password: url.pass,
        database: url.db
    } : url.full)
    const conn: Conn = {
        query<T extends QueryResultRow>(sql: string, parameters: any[] = []): Promise<T[]> {
            return connection.query<T>(sql).then(result => result.recordset)
        },
        async queryArrayMode(sql: string, parameters: any[] = []): Promise<QueryResultArrayMode> {
            const request = connection.request() as any
            request.arrayRowMode = true
            const results: IResult<ColumnValue[]> & { columns: ColumnMetadata[][] } = await request.query(sql)
            return {rows: results.recordset as ColumnValue[][], fields: results.columns[0]}
        }
    }
    return exec(conn)
        .then(res => connection.close().then(_ => res))
        .catch(err => connection.close().then(_ => Promise.reject(err)))
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
