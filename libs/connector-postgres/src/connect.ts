import {DatabaseUrlParsed} from "@azimutt/database-types";
import {Client} from "pg";

export function connect<T>(url: DatabaseUrlParsed, exec: (c: Client) => Promise<T>): Promise<T> {
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
