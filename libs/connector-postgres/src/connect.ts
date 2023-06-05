import {DatabaseUrlParsed} from "@azimutt/database-types";
import {Client, QueryResultRow} from "pg";

export function connect<T>(application: string, url: DatabaseUrlParsed, exec: (c: Client) => Promise<T>): Promise<T> {
    const client = new Client({
        application_name: application,
        connectionString: buildUrl(url),
        ssl: {rejectUnauthorized: false}
    })
    return client.connect().then(_ => {
        return exec(client)
            .then(res => client.end().then(_ => res))
            .catch(err => client.end().then(_ => Promise.reject(err)))
    })
}

function buildUrl(url: DatabaseUrlParsed): string {
    const userPass = url.user && url.pass ? `${url.user}:${url.pass}@` : ''
    const port = url.port ? `:${url.port}` : ''
    return `postgresql://${userPass}${url.host}${port}/${url.db}`
}

export function query<T extends QueryResultRow>(client: Client, sql: string, parameters: any[] = []): Promise<T[]> {
    return client.query<T>(sql, parameters).then(res => res.rows)
}
