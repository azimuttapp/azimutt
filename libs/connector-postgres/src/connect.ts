import {Client, types} from "pg";
import {DatabaseUrlParsed} from "@azimutt/database-types";
import {Conn, QueryResultArrayMode, QueryResultRow} from "./common";

export function connect<T>(application: string, url: DatabaseUrlParsed, exec: (c: Conn) => Promise<T>): Promise<T> {
    types.setTypeParser(types.builtins.INT8, (val: string) => parseInt(val, 10))
    const client = new Client({
        application_name: application,
        connectionString: buildUrl(url)
    })
    const conn: Conn = {
        query<T extends QueryResultRow>(sql: string, parameters: any[] = []): Promise<T[]> {
            return client.query<T>(sql, parameters).then(res => res.rows, err => Promise.reject(queryError(sql, err)))
        },
        queryArrayMode(sql: string, parameters: any[] = []): Promise<QueryResultArrayMode> {
            return client.query({text: sql, values: parameters, rowMode: 'array'}).then(null, err => Promise.reject(queryError(sql, err)))
        }
    }
    return client.connect().then(_ => exec(conn).then(
        res => client.end().then(_ => res),
        err => client.end().then(_ => Promise.reject(err))
    ))
}

function buildUrl(url: DatabaseUrlParsed): string {
    const userPass = url.user && url.pass ? `${url.user}:${url.pass}@` : ''
    const port = url.port ? `:${url.port}` : ''
    const options = url.options ? `?${url.options}` : ''
    return `postgresql://${userPass}${url.host}${port}/${url.db}${options}`
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
