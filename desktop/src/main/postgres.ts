import {Client, QueryResult} from "pg"
import {DbUrl} from "./database-url"

export async function query(url: DbUrl, query: string): Promise<QueryResult> {
    return await connect(url, async client => {
        return await client.query(query)
    })
}

function connect<T>(url: DbUrl, exec: (c: Client) => Promise<T>): Promise<T> {
    const client = new Client({
        application_name: 'azimutt-desktop',
        connectionString: `postgresql://${url.user}:${url.pass}@${url.host}:${url.port}/${url.db}`,
        ssl: {rejectUnauthorized: false}
    })
    return client.connect().then(_ => {
        return exec(client)
            .then(res => client.end().then(_ => res))
            .catch(err => client.end().then(_ => Promise.reject(err)))
    })
}
