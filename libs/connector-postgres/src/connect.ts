import {Client, ClientConfig, types} from "pg";
import {AnyError, errorToString, Logger} from "@azimutt/utils";
import {DatabaseUrlParsed, logQueryIfNeeded} from "@azimutt/database-types";
import {Conn, QueryResultArrayMode, QueryResultRow} from "./common";

export type PostgresConnectOpts = {logger: Logger, logQueries: boolean}
export async function connect<T>(application: string, url: DatabaseUrlParsed, exec: (c: Conn) => Promise<T>, {logger, logQueries}: PostgresConnectOpts): Promise<T> {
    types.setTypeParser(types.builtins.INT8, (val: string) => parseInt(val, 10))
    const client = await createConnection(buildConfig(application, url))
        .catch(_ => createConnection(url.full))
        .catch(err => Promise.reject(connectionError(err)))
    let queryCpt = 1
    const conn: Conn = {
        query<T extends QueryResultRow>(sql: string, parameters: any[] = [], name?: string): Promise<T[]> {
            return logQueryIfNeeded(queryCpt++, name, sql, parameters, (sql, parameters) => {
                return client.query<T>(sql, parameters).then(res => res.rows, err => Promise.reject(queryError(sql, err)))
            }, r => r.length, logger, logQueries)
        },
        queryArrayMode(sql: string, parameters: any[] = [], name?: string): Promise<QueryResultArrayMode> {
            return logQueryIfNeeded(queryCpt++, name, sql, parameters, (sql, parameters) => {
                return client.query({text: sql, values: parameters, rowMode: 'array'}).then(null, err => Promise.reject(queryError(sql, err)))
            }, r => r.rows.length, logger, logQueries)
        }
    }
    return exec(conn).then(
        res => client.end().then(_ => res),
        err => client.end().then(_ => Promise.reject(err))
    )
}

async function createConnection(config: string | ClientConfig): Promise<Client> {
    const client = new Client(config)
    return client.connect().then(_ => client)
}

function buildConfig(application: string, url: DatabaseUrlParsed): ClientConfig {
    return {
        application_name: application,
        host: url.host,
        port: url.port,
        user: url.user,
        password: url.pass || undefined,
        database: url.db,
        // ssl: { rejectUnauthorized: false } // needs `?sslmode=no-verify` at the end of the connection string
        // TODO: miss url options like sslmode...
    }
}

function connectionError(err: AnyError): AnyError {
    const msg = errorToString(err)
    if (msg.match(/^no pg_hba.conf entry for host "[^"]+", user "[^"]+", database "[^"]+", no encryption$/) || msg.match(/^SSL connection is required$/)) {
        return new Error(`${msg}. Try adding \`?sslmode=no-verify\` at the end of your url.`)
    } else {
        return err
    }
}

function queryError(sql: string, err: unknown): Error {
    if (typeof err === 'object' && err !== null) {
        return new Error(`${err.constructor.name}${'code' in err ? ` ${err.code}` : ''}${'message' in err ? `:\n ${err.message}` : ''}\n on '${sql}'`)
    } else if (err) {
        return new Error(`error ${JSON.stringify(err)}\n on '${sql}'`)
    } else {
        return new Error(`error on '${sql}'`)
    }
}
