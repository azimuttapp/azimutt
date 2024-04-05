import {Connector, DatabaseKind, DatabaseUrlParsed} from "@azimutt/database-model"
import {bigquery} from "@azimutt/connector-bigquery"
import {couchbase} from "@azimutt/connector-couchbase"
import {mariadb} from "@azimutt/connector-mariadb"
import {mongodb} from "@azimutt/connector-mongodb"
import {mysql} from "@azimutt/connector-mysql"
import {postgres} from "@azimutt/connector-postgres"
import {snowflake} from "@azimutt/connector-snowflake"
import {sqlserver} from "@azimutt/connector-sqlserver"

const connectors: Record<DatabaseKind, Connector | undefined> = {
    bigquery: bigquery,
    cassandra: undefined,
    couchbase: couchbase,
    db2: undefined,
    elasticsearch: undefined,
    mariadb: mariadb,
    mongodb: mongodb,
    mysql: mysql,
    oracle: undefined,
    postgres: postgres,
    redis: undefined,
    snowflake: snowflake,
    sqlite: undefined,
    sqlserver: sqlserver,
}

export function getConnector(url: DatabaseUrlParsed): Connector | undefined {
    return url.kind ? connectors[url.kind] : undefined
}

export function availableConnectors(): DatabaseKind[] {
    return Object.entries(connectors).filter(([_, c]) => !!c).map(([kind, _]) => kind as DatabaseKind)
}
