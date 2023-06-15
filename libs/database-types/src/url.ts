import {z} from "zod";
import {filterValues} from "@azimutt/utils";

export type DatabaseUrl = string
export const DatabaseUrl = z.string()
export type DatabaseUrlParsed = { full: string, kind?: DatabaseKind, user?: string, pass?: string, host?: string, port?: number, db?: string, options?: string }
export type DatabaseKind = 'couchbase' | 'mariadb' | 'mongodb' | 'mysql' | 'oracle' | 'postgres' | 'sqlite' | 'sqlserver'

// vertically align regexes with variable names ^^
const couchbaseRegexpLonger = /^couchbases?:\/\/(?:([^:]+):([^@]+)@)?([^:/?]+)(?::(\d+))?(?:\/([^?]+))?$/
const mariadbRegexpLo = /^(?:jdbc:)?mariadb:\/\/(?:([^:]+):([^@]+)@)?([^:/?]+)(?::(\d+))?(?:\/([^?]+))?$/
const mongoRegexLonger = /mongodb(?:\+srv)?:\/\/(?:([^:]+):([^@]+)@)?([^:/?]+)(?::(\d+))?(?:\/([^?]+))?(?:\?(.+))?/
const mysqlRegexpLonger = /^(?:jdbc:)?mysql:\/\/(?:([^:]+):([^@]+)@)?([^:/?]+)(?::(\d+))?(?:\/([^?]+))?$/
const postres = /^(?:jdbc:)?postgres(?:ql)?:\/\/(?:([^:]+):([^@]+)@)?([^:/?]+)(?::(\d+))?(?:\/([^?]+))?$/
const sqlser = /^(?:jdbc:)?sqlserver(?:ql)?:\/\/(?:([^:]+):([^@]+)@)?([^:/?]+)(?::(\d+))?(?:\/([^?]+))?$/

export function parseDatabaseUrl(url: DatabaseUrl): DatabaseUrlParsed {
    const couchbaseMatches = url.match(couchbaseRegexpLonger)
    if (couchbaseMatches) {
        const [, user, pass, host, port, db] = couchbaseMatches
        const opts = {kind: 'couchbase', user, pass, host, port: port ? parseInt(port) : undefined, db}
        return {...filterValues(opts, v => v !== undefined), full: url}
    }

    const mariadbMatches = url.match(mariadbRegexpLo)
    if (mariadbMatches) {
        const [, user, pass, host, port, db] = mariadbMatches
        const opts = {kind: 'mariadb', user, pass, host, port: port ? parseInt(port) : undefined, db}
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

    const sqlserverMatches = url.match(sqlser) || parseSqlServerUrl(url)
    if (sqlserverMatches) {
        const [, user, pass, host, port, db] = sqlserverMatches
        const opts = {kind: 'sqlserver', user, pass, host, port: port ? parseInt(port) : undefined, db}
        return {...filterValues(opts, v => v !== undefined), full: url}
    }

    return {full: url}
}

function parseSqlServerUrl(url: DatabaseUrl): string[] | null {
    const props = Object.fromEntries(url.split(';').map(part => part.split('=')))
    if (props['Server'] && props['Database'] && props['User Id'] && props['Password']) {
        const [host, port] = props['Server'].split(',')
        if (host && port) {
            return [url, props['User Id'], props['Password'], host, port, props['Database']]
        }
    }
    return null
}
