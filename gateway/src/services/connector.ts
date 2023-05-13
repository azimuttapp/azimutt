import {Connector, DatabaseUrlParsed} from "@azimutt/database-types";
import {couchbase} from "@azimutt/connector-couchbase";
import {mongodb} from "@azimutt/connector-mongodb";
import {postgres} from "@azimutt/connector-postgres";

export function getConnector(url: DatabaseUrlParsed): Connector | undefined {
    if (url.kind === 'couchbase') {
        return couchbase
    } else if (url.kind === 'mongodb') {
        return mongodb
    } else if (url.kind === 'postgres') {
        return postgres
    } else {
        return undefined
    }
}
