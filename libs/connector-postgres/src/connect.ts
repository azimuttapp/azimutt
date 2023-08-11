import {Client, types} from "pg";
import {DatabaseUrlParsed} from "@azimutt/database-types";
import {Conn, QueryResultArrayMode, QueryResultRow} from "./common";

export function connect<T>(application: string, url: DatabaseUrlParsed, exec: (c: Conn) => Promise<T>): Promise<T> {
    types.setTypeParser(types.builtins.INT8, (val: string) => parseInt(val, 10))
    const client = new Client({
        application_name: application,
        connectionString: buildUrl(url),
        ssl: {rejectUnauthorized: false}
    })
    const conn: Conn = {
        query<T extends QueryResultRow>(sql: string, parameters: any[] = []): Promise<T[]> {
            return client.query<T>(sql, parameters).then(res => res.rows)
        },
        queryArrayMode(sql: string, parameters: any[] = []): Promise<QueryResultArrayMode> {
            return client.query({text: sql, values: parameters, rowMode: 'array'})
        }
    }
    return client.connect().then(_ => {
        return exec(conn)
            .then(res => client.end().then(_ => res))
            .catch(err => client.end().then(_ => Promise.reject(err)))
    })
}

function buildUrl(url: DatabaseUrlParsed): string {
    const userPass = url.user && url.pass ? `${url.user}:${url.pass}@` : ''
    const port = url.port ? `:${url.port}` : ''
    const options = url.options ? `?${url.options}` : ''
    return `postgresql://${userPass}${url.host}${port}/${url.db}${options}`
}
