import {z} from "zod";
import {filterValues} from "@azimutt/utils";

export type DatabaseUrl = string
export const DatabaseUrl = z.string()
export type DatabaseUrlParsed = { full: string, kind?: DatabaseKind, user?: string, pass?: string, host?: string, port?: number, db?: string, options?: string }
export type DatabaseKind = 'couchbase' | 'mariadb' | 'mongodb' | 'mysql' | 'oracle' | 'postgres' | 'sqlite' | 'sqlserver'

// vertically align regexes with variable names ^^
const couchbaseRegexp = /^couchbases?:\/\/(?:([^:]+):([^@]+)@)?([^:/?]+)(?::(\d+))?(?:\/([^?]+))?$/
const mongoRegex = /mongodb(?:\+srv)?:\/\/(?:([^:]+):([^@]+)@)?([^:/?]+)(?::(\d+))?(?:\/([^?]+))?(?:\?(.+))?/
const mysqlRegexp = /^(?:jdbc:)?mysql:\/\/(?:([^:]+):([^@]+)@)?([^:/?]+)(?::(\d+))?(?:\/([^?]+))?$/
const p = /^(?:jdbc:)?postgres(?:ql)?:\/\/(?:([^:]+):([^@]+)@)?([^:/?]+)(?::(\d+))?(?:\/([^?]+))?$/

export function parseDatabaseUrl(url: DatabaseUrl): DatabaseUrlParsed {
    const couchbase = url.match(couchbaseRegexp)
    if (couchbase) {
        const [, user, pass, host, port, db] = couchbase
        const opts = {kind: 'couchbase', user, pass, host, port: port ? parseInt(port) : undefined, db}
        return {...filterValues(opts, v => v !== undefined), full: url}
    }

    const mongo = url.match(mongoRegex)
    if (mongo) {
        const [, user, pass, host, port, db, options] = mongo
        const opts = {kind: 'mongodb', user, pass, host, port: port ? parseInt(port) : undefined, db, options}
        return {...filterValues(opts, v => v !== undefined), full: url}
    }

    const mysql = url.match(mysqlRegexp)
    if (mysql) {
        const [, user, pass, host, port, db] = mysql
        const opts = {kind: 'mysql', user, pass, host, port: port ? parseInt(port) : undefined, db}
        return {...filterValues(opts, v => v !== undefined), full: url}
    }

    const postgres = url.match(p)
    if (postgres) {
        const [, user, pass, host, port, db] = postgres
        const opts = {kind: 'postgres', user, pass, host, port: port ? parseInt(port) : undefined, db}
        return {...filterValues(opts, v => v !== undefined), full: url}
    }

    return {full: url}
}
