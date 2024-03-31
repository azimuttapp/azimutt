import * as couchbase from "couchbase";
import {Cluster, ConnectOptions} from "couchbase";
import {ConnectorDefaultOpts, DatabaseUrlParsed} from "@azimutt/database-model";

export async function connect<T>(application: string, url: DatabaseUrlParsed, exec: (c: Conn) => Promise<T>, opts: ConnectorDefaultOpts): Promise<T> {
    const cluster: Cluster = await createConnection(application, url)
    const conn: Conn = {
        underlying: cluster
    }
    return exec(conn).then(
        res => cluster.close().then(_ => res),
        err => cluster.close().then(_ => Promise.reject(err))
    )
}

export interface Conn {
    underlying: Cluster
}

async function createConnection(application: string, url: DatabaseUrlParsed): Promise<Cluster> {
    const options: ConnectOptions = {
        username: url.user,
        password: url.pass
    }
    return couchbase.connect(url.full, options)
}
