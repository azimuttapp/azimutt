import * as couchbase from "couchbase";
import {Cluster, ConnectOptions} from "couchbase";
import {AnyError} from "@azimutt/utils";
import {ConnectorDefaultOpts, DatabaseUrlParsed} from "@azimutt/models";

export async function connect<T>(application: string, url: DatabaseUrlParsed, exec: (c: Conn) => Promise<T>, opts: ConnectorDefaultOpts): Promise<T> {
    const cluster: Cluster = await createConnection(application, url).catch(err => Promise.reject(connectionError(err)))
    const conn: Conn = {url, underlying: cluster}
    return exec(conn).then(
        res => cluster.close().then(_ => res),
        err => cluster.close().then(_ => Promise.reject(err))
    )
}

export interface Conn {
    url: DatabaseUrlParsed
    underlying: Cluster
}

async function createConnection(application: string, url: DatabaseUrlParsed): Promise<Cluster> {
    const options: ConnectOptions = {
        username: url.user,
        password: url.pass
    }
    return couchbase.connect(url.full, options)
}

function connectionError(err: AnyError): AnyError {
    // TODO: improve error messages here if needed
    return err
}
