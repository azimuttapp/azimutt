import {Connector, DatabaseUrlParsed} from "@azimutt/database-types"
import {couchbase} from "@azimutt/connector-couchbase"
import {mongodb} from "@azimutt/connector-mongodb"
import {mysql} from "@azimutt/connector-mysql"
import {postgres} from "@azimutt/connector-postgres"
import {sqlserver} from "@azimutt/connector-sqlserver"

export function getConnector(url: DatabaseUrlParsed): Connector | undefined {
    if (url.kind === 'couchbase') {
        return couchbase
    } else if (url.kind === 'mongodb') {
        return mongodb
    } else if (url.kind === 'mysql') {
        return mysql
    } else if (url.kind === 'postgres') {
        return postgres
    } else if (url.kind === 'sqlserver') {
        return sqlserver
    } else {
        return undefined
    }
}
