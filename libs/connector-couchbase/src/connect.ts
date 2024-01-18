import * as couchbase from "couchbase";
import {Cluster, ConnectOptions} from "couchbase";
import {DatabaseUrlParsed} from "@azimutt/database-types";

export async function connect<T>(application: string, url: DatabaseUrlParsed, exec: (c: Cluster) => Promise<T>): Promise<T> {
    const cluster: Cluster = await createConnection(application, url)
    return exec(cluster).then(
        res => cluster.close().then(_ => res),
        err => cluster.close().then(_ => Promise.reject(err))
    )
}

async function createConnection(application: string, url: DatabaseUrlParsed): Promise<Cluster> {
    const options: ConnectOptions = {
        username: url.user,
        password: url.pass
    }
    return couchbase.connect(url.full, options)
}
