import {
  Connection,
  ConnectionAttributes,
  getConnection,
  SYSDBA,
} from "oracledb"
import { AnyError, errorToString } from "@azimutt/utils"
import {
  AttributeValue,
  ConnectorDefaultOpts,
  DatabaseUrlParsed,
  logQueryIfNeeded,
  queryError,
} from "@azimutt/models"

export async function connect<T>(
  application: string,
  url: DatabaseUrlParsed,
  exec: (c: Conn) => Promise<T>,
  opts: ConnectorDefaultOpts
): Promise<T> {
  const client = await createConnection(buildConfig(application, url)).catch(
    (err) => Promise.reject(connectionError(err))
  )
  let queryCpt = 1
  const conn: Conn = {
    url,
    query<T extends QueryResultRow>(
      sql: string,
      parameters: [] = [],
      name?: string
    ): Promise<T[]> {
      return logQueryIfNeeded(
        queryCpt++,
        name,
        sql,
        parameters,
        (sql, parameters) => {
          return client.execute<T>(sql, parameters).then(
            (res) => res.rows ?? [],
            (err) => Promise.reject(queryError(name, sql, err))
          )
        },
        (r) => r?.length ?? 0,
        opts
      )
    },
    queryArrayMode(
      sql: string,
      parameters: any[] = [],
      name?: string
    ): Promise<QueryResultArrayMode> {
      return logQueryIfNeeded(
        queryCpt++,
        name,
        sql,
        parameters,
        (sql, parameters) => {
          return client.execute(sql, parameters).then(
            (res) => {
              const { metaData, rows } = res
              const fields = metaData?.map((meta) => ({
                name: meta.name,
              }))
              return { fields: fields ?? [], rows: (rows as any[]) ?? [] }
            },
            (err) => Promise.reject(queryError(name, sql, err))
          )
        },
        (r) => r.rows.length,
        opts
      )
    },
  }
  return exec(conn).then(
    (res) => client.close().then((_) => res),
    (err) => client.close().then((_) => Promise.reject(err))
  )
}

export interface Conn {
  url: DatabaseUrlParsed

  query<T extends QueryResultRow>(
    sql: string,
    parameters?: any[],
    name?: string
  ): Promise<T[]>

  queryArrayMode(
    sql: string,
    parameters?: any[],
    name?: string
  ): Promise<QueryResultArrayMode>
}

export type QueryResultValue = AttributeValue
export type QueryResultRow = QueryResultValue[]
export type QueryResultField = {
  name: string
}
export type QueryResultRowArray = QueryResultValue[]
export type QueryResultArrayMode = {
  fields: QueryResultField[]
  rows: QueryResultRowArray[]
}

async function createConnection(
  config: ConnectionAttributes
): Promise<Connection> {
  const client = await getConnection(config)
  return client
}

function buildConfig(
  application: string,
  url: DatabaseUrlParsed
): ConnectionAttributes {
  return {
    connectionString: `${url.host}:${url.port}/${url.db}`,
    user: url.user,
    password: url.pass || undefined,
    privilege: SYSDBA,
  }
}

function connectionError(err: AnyError): AnyError {
  const msg = errorToString(err)
  return err
}
