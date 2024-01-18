import {MongoClient, MongoClientOptions} from "mongodb";
import {DatabaseUrlParsed} from "@azimutt/database-types";

export async function connect<T>(application: string, url: DatabaseUrlParsed, exec: (c: MongoClient) => Promise<T>): Promise<T> {
    const client: MongoClient = await createConnection(application, url)
    return exec(client).then(
        res => client.close().then(_ => res),
        err => client.close().then(_ => Promise.reject(err))
    )
}

async function createConnection(application: string, url: DatabaseUrlParsed): Promise<MongoClient> {
    const options: MongoClientOptions = {
        appName: application
    }
    const client: MongoClient = new MongoClient(url.full, options)
    return client.connect().then(_ => client)
}
