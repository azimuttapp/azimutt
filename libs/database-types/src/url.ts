import {z} from "zod";
import {filterValues} from "@azimutt/utils";

export type DatabaseUrl = string
export const DatabaseUrl = z.string()
export type DatabaseUrlParsed = { full: string, kind?: DatabaseKind, user?: string, pass?: string, host?: string, port?: number, db?: string, options?: string }
export type DatabaseKind = 'couchbase' | 'mariadb' | 'mongodb' | 'mysql' | 'oracle' | 'postgres' | 'sqlite' | 'sqlserver'

// vertically align regexes with variable names ^^
const couchbaseRegexpLonger = /^couchbases?:\/\/(?:([^:]+):([^@]+)@)?([^:/?]+)(?::(\d+))?(?:\/([^?]+))?$/
const mongoRegexLonger = /mongodb(?:\+srv)?:\/\/(?:([^:]+):([^@]+)@)?([^:/?]+)(?::(\d+))?(?:\/([^?]+))?(?:\?(.+))?/
const mysqlRegexpLonger = /^(?:jdbc:)?mysql:\/\/(?:([^:]+):([^@]+)@)?([^:/?]+)(?::(\d+))?(?:\/([^?]+))?$/
const postres = /^(?:jdbc:)?postgres(?:ql)?:\/\/(?:([^:]+):([^@]+)@)?([^:/?]+)(?::(\d+))?(?:\/([^?]+))?$/
const sqlser = /^(?:jdbc:)?sqlserver(?:ql)?:\/\/(?:([^:]+):([^@]+)@)?([^:/?]+)(?::(\d+))?(?:\/([^?]+))?$/
const sqlserverRegex = /^Server=([^,]+),(\d+);Database=([^;]+);User Id=([^;]+);Password=([^;]+)$/

export function parseDatabaseUrl(url: DatabaseUrl): DatabaseUrlParsed {
    const couchbase = url.match(couchbaseRegexpLonger)
    if (couchbase) {
        const [, user, pass, host, port, db] = couchbase
        const opts = {kind: 'couchbase', user, pass, host, port: port ? parseInt(port) : undefined, db}
        return {...filterValues(opts, v => v !== undefined), full: url}
    }

    const mongo = url.match(mongoRegexLonger)
    if (mongo) {
        const [, user, pass, host, port, db, options] = mongo
        const opts = {kind: 'mongodb', user, pass, host, port: port ? parseInt(port) : undefined, db, options}
        return {...filterValues(opts, v => v !== undefined), full: url}
    }

    const mysql = url.match(mysqlRegexpLonger)
    if (mysql) {
        const [, user, pass, host, port, db] = mysql
        const opts = {kind: 'mysql', user, pass, host, port: port ? parseInt(port) : undefined, db}
        return {...filterValues(opts, v => v !== undefined), full: url}
    }

    const postgres = url.match(postres)
    if (postgres) {
        const [, user, pass, host, port, db] = postgres
        const opts = {kind: 'postgres', user, pass, host, port: port ? parseInt(port) : undefined, db}
        return {...filterValues(opts, v => v !== undefined), full: url}
    }

    const sqlserver = url.match(sqlser)
    if (sqlserver) {
        const [, user, pass, host, port, db] = sqlserver
        const opts = {kind: 'sqlserver', user, pass, host, port: port ? parseInt(port) : undefined, db}
        return {...filterValues(opts, v => v !== undefined), full: url}
    }

    const sqlserver2 = url.match(sqlserverRegex)
    if (sqlserver2) {
        const [, host, port, db, user, pass] = sqlserver2
        const opts = {kind: 'sqlserver', user, pass, host, port: port ? parseInt(port) : undefined, db}
        return {...filterValues(opts, v => v !== undefined), full: url}
    }

    return {full: url}
}
