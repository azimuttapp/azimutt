import mssql, {config, ConnectionPool, IOptions, IResult, ISqlType} from "mssql";
import {AnyError} from "@azimutt/utils";
import {
    AttributeValue,
    ConnectorDefaultOpts,
    DatabaseUrlParsed,
    logQueryIfNeeded,
    parseDatabaseOptions,
    queryError
} from "@azimutt/models";

export async function connect<T>(application: string, url: DatabaseUrlParsed, exec: (c: Conn) => Promise<T>, opts: ConnectorDefaultOpts): Promise<T> {
    const connection: ConnectionPool = await mssql.connect(buildconfig(application, url))
        .catch(_ => mssql.connect(url.full))
        .catch(err => Promise.reject(connectionError(err)))
    let queryCpt = 1
    const conn: Conn = {
        url,
        query<T extends QueryResultRow>(sql: string, parameters: any[] = [], name: string = ''): Promise<T[]> {
            return logQueryIfNeeded(queryCpt++, name, sql, parameters, (sql, parameters) => {
                return connection.query<T>(sql).then(result => result.recordset, err => Promise.reject(queryError(name, sql, err)))
            }, r => r.length, opts)
        },
        queryArrayMode(sql: string, parameters: any[] = [], name: string = ''): Promise<QueryResultArrayMode> {
            return logQueryIfNeeded(queryCpt++, name, sql, parameters, async (sql, parameters) => {
                const request = connection.request() as any
                request.arrayRowMode = true
                const result: IResult<AttributeValue[]> & { columns: ColumnMetadata[][] } = await request.query(sql)
                    .catch((err: AnyError) => Promise.reject(queryError(name, sql, err)))
                return {rows: result.recordset as AttributeValue[][], fields: result.columns[0]}
            }, r => r.rows.length, opts)
        }
    }
    return exec(conn).then(
        res => connection.close().then(_ => res),
        err => connection.close().then(_ => Promise.reject(err))
    )
}

export interface Conn {
    url: DatabaseUrlParsed

    query<T extends QueryResultRow>(sql: string, parameters?: any[], name?: string): Promise<T[]>

    queryArrayMode(sql: string, parameters?: any[], name?: string): Promise<QueryResultArrayMode>
}

export type QueryResultValue = AttributeValue
export type QueryResultRow = { [column: string]: QueryResultValue }
export type QueryResultField = { name: string }
export type QueryResultRowArray = QueryResultValue[]
export type QueryResultArrayMode = {
    fields: QueryResultField[],
    rows: QueryResultRowArray[]
}

function buildconfig(application: string, url: DatabaseUrlParsed): config {
    const props = parseDatabaseOptions(url.options)
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

function connectionError(err: AnyError): AnyError {
    // TODO: improve error messages here if needed
    return err
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
