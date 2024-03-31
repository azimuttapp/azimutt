import {MongoClient, MongoClientOptions} from "mongodb";
import {ConnectorDefaultOpts, DatabaseUrlParsed} from "@azimutt/database-model";

export async function connect<T>(application: string, url: DatabaseUrlParsed, exec: (c: Conn) => Promise<T>, opts: ConnectorDefaultOpts): Promise<T> {
    const client: MongoClient = await createConnection(application, url)
    const conn: Conn = {
        underlying: client
    }
    return exec(conn).then(
        res => client.close().then(_ => res),
        err => client.close().then(_ => Promise.reject(err))
    )
}

export interface Conn {
    underlying: MongoClient
}

async function createConnection(application: string, url: DatabaseUrlParsed): Promise<MongoClient> {
    const options: MongoClientOptions = {
        appName: application
    }
    const client: MongoClient = new MongoClient(url.full, options)
    return client.connect().then(_ => client)
}
