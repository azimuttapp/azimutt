import {MongoClient, MongoClientOptions} from "mongodb";
import {AnyError} from "@azimutt/utils";
import {ConnectorDefaultOpts, DatabaseUrlParsed} from "@azimutt/models";

export async function connect<T>(application: string, url: DatabaseUrlParsed, exec: (c: Conn) => Promise<T>, opts: ConnectorDefaultOpts): Promise<T> {
    const client: MongoClient = await createConnection(application, url).catch(err => Promise.reject(connectionError(err)))
    const conn: Conn = {url, underlying: client}
    return exec(conn).then(
        res => client.close().then(_ => res),
        err => client.close().then(_ => Promise.reject(err))
    )
}

export interface Conn {
    url: DatabaseUrlParsed
    underlying: MongoClient
}

async function createConnection(application: string, url: DatabaseUrlParsed): Promise<MongoClient> {
    const options: MongoClientOptions = {
        appName: application
    }
    const client: MongoClient = new MongoClient(url.full, options)
    return client.connect().then(_ => client)
}

function connectionError(err: AnyError): AnyError {
    // TODO: improve error messages here if needed
    return err
}
