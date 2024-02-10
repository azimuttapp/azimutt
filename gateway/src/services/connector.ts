import {Connector, DatabaseKind, DatabaseUrlParsed} from "@azimutt/database-types"
import {couchbase} from "@azimutt/connector-couchbase"
import {mariadb} from "@azimutt/connector-mariadb"
import {mongodb} from "@azimutt/connector-mongodb"
import {mysql} from "@azimutt/connector-mysql"
import {postgres} from "@azimutt/connector-postgres"
import {snowflake} from "@azimutt/connector-snowflake"
import {sqlserver} from "@azimutt/connector-sqlserver"

const connectors: Record<DatabaseKind, Connector | undefined> = {
    couchbase: couchbase,
    mariadb: mariadb,
    mongodb: mongodb,
    mysql: mysql,
    oracle: undefined,
    postgres: postgres,
    snowflake: snowflake,
    sqlite: undefined,
    sqlserver: sqlserver
}

export function getConnector(url: DatabaseUrlParsed): Connector | undefined {
    return url.kind ? connectors[url.kind] : undefined
}

export function availableConnectors(): DatabaseKind[] {
    return Object.keys(connectors) as DatabaseKind[]
}
