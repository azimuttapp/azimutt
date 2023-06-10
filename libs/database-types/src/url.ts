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
    const couchbaseMatches = url.match(couchbaseRegexpLonger)
    if (couchbaseMatches) {
        const [, user, pass, host, port, db] = couchbaseMatches
        const opts = {kind: 'couchbase', user, pass, host, port: port ? parseInt(port) : undefined, db}
        return {...filterValues(opts, v => v !== undefined), full: url}
    }

    const mongodbMatches = url.match(mongoRegexLonger)
    if (mongodbMatches) {
        const [, user, pass, host, port, db, options] = mongodbMatches
        const opts = {kind: 'mongodb', user, pass, host, port: port ? parseInt(port) : undefined, db, options}
        return {...filterValues(opts, v => v !== undefined), full: url}
    }

    const mysqlMatches = url.match(mysqlRegexpLonger)
    if (mysqlMatches) {
        const [, user, pass, host, port, db] = mysqlMatches
        const opts = {kind: 'mysql', user, pass, host, port: port ? parseInt(port) : undefined, db}
        return {...filterValues(opts, v => v !== undefined), full: url}
    }

    const postgresMatches = url.match(postres)
    if (postgresMatches) {
        const [, user, pass, host, port, db] = postgresMatches
        const opts = {kind: 'postgres', user, pass, host, port: port ? parseInt(port) : undefined, db}
        return {...filterValues(opts, v => v !== undefined), full: url}
    }

    const sqlserverMatches = url.match(sqlser)
    if (sqlserverMatches) {
        const [, user, pass, host, port, db] = sqlserverMatches
        const opts = {kind: 'sqlserver', user, pass, host, port: port ? parseInt(port) : undefined, db}
        return {...filterValues(opts, v => v !== undefined), full: url}
    }

    const sqlserverMatches2 = url.match(sqlserverRegex)
    if (sqlserverMatches2) {
        const [, host, port, db, user, pass] = sqlserverMatches2
        const opts = {kind: 'sqlserver', user, pass, host, port: port ? parseInt(port) : undefined, db}
        return {...filterValues(opts, v => v !== undefined), full: url}
    }

    return {full: url}
}
