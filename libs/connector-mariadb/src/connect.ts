import * as mariadb from "mariadb";
import {Connection, ConnectionConfig} from "mariadb";
import {AnyError} from "@azimutt/utils";
import {
    AttributeValue,
    ConnectorDefaultOpts,
    DatabaseUrlParsed,
    logQueryIfNeeded,
    queryError,
    QueryField
} from "@azimutt/models";

export async function connect<T>(application: string, url: DatabaseUrlParsed, exec: (c: Conn) => Promise<T>, opts: ConnectorDefaultOpts): Promise<T> {
    const connection: Connection = await mariadb.createConnection(buildConfig(application, url))
        .catch(_ => mariadb.createConnection(url.full))
        .catch(err => Promise.reject(connectionError(err)))
    let queryCpt = 1
    const conn: Conn = {
        url,
        query<T extends QueryResultRow>(sql: string, parameters: any[] = [], name?: string): Promise<T[]> {
            return logQueryIfNeeded(queryCpt++, name, sql, parameters, (sql, parameters) => {
                return connection.query<T[]>({sql, namedPlaceholders: true}, parameters).catch(err => Promise.reject(queryError(name, sql, err)))
            }, r => r.length, opts)
        },
        queryArrayMode(sql: string, parameters: any[] = [], name?: string): Promise<QueryResultArrayMode> {
            return logQueryIfNeeded(queryCpt++, name, sql, parameters, (sql, parameters) => {
                return connection.query({sql, namedPlaceholders: true, rowsAsArray: true}, parameters).then(rows => ({
                    rows,
                    /*
                        see https://github.com/mariadb-corporation/mariadb-connector-nodejs/blob/master/documentation/promise-api.md#column-metadata
                        `rows` result has a `meta` property with columns metadata as [ColumnDef](https://github.com/mariadb-corporation/mariadb-connector-nodejs/blob/master/lib/cmd/column-definition.js)
                        sadly this class is not public, so falling back to any :/
                     */
                    fields: (rows.meta as any[]).map(field => ({
                        schema: field.schema() || undefined, // same as f.db()
                        table: field.orgTable() || undefined,
                        tableAlias: field.table() || undefined,
                        column: field.orgName() || undefined,
                        name: field.name(),
                        type: field.type, // see https://github.com/mariadb-corporation/mariadb-connector-nodejs/blob/master/lib/const/field-type.js
                        flags: field.flags // see https://github.com/mariadb-corporation/mariadb-connector-nodejs/blob/master/lib/const/field-detail.js
                    }))
                }), err => Promise.reject(queryError(name, sql, err)))
            }, r => r.rows.length, opts)
        }
    }
    return exec(conn).then(
        res => connection.end().then(_ => res),
        err => connection.end().then(_ => Promise.reject(err))
    )
}

export interface Conn {
    url: DatabaseUrlParsed

    query<T extends QueryResultRow>(sql: string, parameters?: any[], name?: string): Promise<T[]>

    queryArrayMode(sql: string, parameters?: any[], name?: string): Promise<QueryResultArrayMode>
}

export type QueryResultValue = AttributeValue
export type QueryResultRow = { [column: string]: QueryResultValue }
export type QueryResultField = QueryField & { tableAlias: string | undefined, type: string, flags: number }
export type QueryResultRowArray = QueryResultValue[]
export type QueryResultArrayMode = { fields: QueryResultField[], rows: QueryResultRowArray[] }

function buildConfig(application: string, url: DatabaseUrlParsed): ConnectionConfig {
    return {
        host: url.host,
        port: url.port,
        user: url.user,
        password: url.pass,
        database: url.db,
        bigIntAsNumber: true,
        // ssl
    }
}

function connectionError(err: AnyError): AnyError {
    // TODO: improve error messages here if needed
    return err
}
