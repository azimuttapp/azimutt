import {z} from "zod";
import {filterValues} from "@azimutt/utils";

export type DatabaseUrl = string
export const DatabaseUrl = z.string()
export type DatabaseUrlParsed = { full: string, kind?: DatabaseKind, user?: string, pass?: string, host?: string, port?: number, db?: string, options?: string }
export type DatabaseKind = 'couchbase' | 'mariadb' | 'mongodb' | 'mysql' | 'oracle' | 'postgres' | 'snowflake' | 'sqlite' | 'sqlserver'

// vertically align regexes with variable names ^^
const couchbaseRegexpLonger = /^couchbases?:\/\/(?:([^:]+):([^@]*)@)?([^:/?]+)(?::(\d+))?(?:\/([^?]+))?(?:\?(.+))?$/
const mariadbRegexpLo = /^(?:jdbc:)?mariadb:\/\/(?:([^:]+):([^@]*)@)?([^:/?]+)(?::(\d+))?(?:\/([^?]+))?(?:\?(.+))?$/
const mongoRegexLonger = /mongodb(?:\+srv)?:\/\/(?:([^:]+):([^@]*)@)?([^:/?]+)(?::(\d+))?(?:\/([^?]+))?(?:\?(.+))?$/
const mysqlRegexpLonger = /^(?:jdbc:)?mysql:\/\/(?:([^:]+):([^@]*)@)?([^:/?]+)(?::(\d+))?(?:\/([^?]+))?(?:\?(.+))?$/
const postres = /^(?:jdbc:)?postgres(?:ql)?:\/\/(?:([^:]+):([^@]*)@)?([^:/?]+)(?::(\d+))?(?:\/([^?]+))?(?:\?(.+))?$/
const sqlser = /^(?:jdbc:)?sqlserver(?:ql)?:\/\/(?:([^:]+):([^@]*)@)?([^:/?]+)(?::(\d+))?(?:\/([^?]+))?(?:\?(.+))?$/
const snowflakeRege = /^(?:jdbc:)?snowflake:\/\/(?:([^:]+):([^@]*)@)?([^:/?]+)(?::(\d+))?(?:\/([^?]+))?(?:\?(.+))?$/
const snowflakeRegexLongerrrrrrrr = /^https:\/\/(?:([^:]+):([^@]*)@)?(.+?(?:\.privatelink)?\.snowflakecomputing\.com)(?::(\d+))?(?:\/([^?]+))?$/

// TODO: duplicated to libs/database-model/src/databaseUrl.ts, update both
export function parseDatabaseUrl(rawUrl: DatabaseUrl): DatabaseUrlParsed {
    const url = rawUrl.trim()

    const couchbaseMatches = url.match(couchbaseRegexpLonger)
    if (couchbaseMatches) {
        const kind: DatabaseKind = 'couchbase'
        const [, user, pass, host, port, db, options] = couchbaseMatches
        const opts = {kind, user, pass, host, port: port ? parseInt(port) : undefined, db, options}
        return {...filterValues(opts, v => v !== undefined), full: url}
    }

    const mariadbMatches = url.match(mariadbRegexpLo)
    if (mariadbMatches) {
        const kind: DatabaseKind = 'mariadb'
        const [, user, pass, host, port, db, options] = mariadbMatches
        const opts = {kind, user, pass, host, port: port ? parseInt(port) : undefined, db, options}
        return {...filterValues(opts, v => v !== undefined), full: url}
    }

    const mongodbMatches = url.match(mongoRegexLonger)
    if (mongodbMatches) {
        const kind: DatabaseKind = 'mongodb'
        const [, user, pass, host, port, db, options] = mongodbMatches
        const opts = {kind, user, pass, host, port: port ? parseInt(port) : undefined, db, options}
        return {...filterValues(opts, v => v !== undefined), full: url}
    }

    const mysqlMatches = url.match(mysqlRegexpLonger)
    if (mysqlMatches) {
        const kind: DatabaseKind = 'mysql'
        const [, user, pass, host, port, db, options] = mysqlMatches
        const opts = {kind, user, pass, host, port: port ? parseInt(port) : undefined, db, options}
        return {...filterValues(opts, v => v !== undefined), full: url}
    }

    const postgresMatches = url.match(postres)
    if (postgresMatches) {
        const kind: DatabaseKind = 'postgres'
        const [, user, pass, host, port, db, options] = postgresMatches
        const opts = {kind, user, pass, host, port: port ? parseInt(port) : undefined, db, options}
        return {...filterValues(opts, v => v !== undefined), full: url}
    }

    const snowflakeMatches = url.match(snowflakeRege) || url.match(snowflakeRegexLongerrrrrrrr)
    if (snowflakeMatches) {
        const kind: DatabaseKind = 'snowflake'
        const [, user, pass, host, port, db, optionsStr] = snowflakeMatches
        const {db: db2, user: user2, ...opts} = Object.fromEntries((optionsStr || '').split('&').map(part => part.split('=')))
        const options = Object.entries(opts).filter(([k, _]) => k).map(([k, v]) => `${k}=${v}`).join('&') || undefined
        const values = {kind, user: user || user2, pass, host, port: port ? parseInt(port) : undefined, db: db || db2, options}
        return {...filterValues(values, v => v !== undefined), full: url}
    }

    const sqlserverMatches = url.match(sqlser) || parseSqlServerUrl(url)
    if (sqlserverMatches) {
        const kind: DatabaseKind = 'sqlserver'
        const [, user, pass, host, port, db, options] = sqlserverMatches
        const opts = {kind, user, pass, host, port: port ? parseInt(port) : undefined, db, options}
        return {...filterValues(opts, v => v !== undefined), full: url}
    }

    return {full: url}
}

// https://www.connectionstrings.com/sql-server 🤯
function parseSqlServerUrl(url: DatabaseUrl): string[] | null {
    const props = Object.fromEntries(url.split(';').map(part => part.split('=')).map(([key, value]) => [key.toLowerCase(), value]))
    const {
        server,
        ['data source']: dataSource,
        database,
        ['initial catalog']: initialCatalog,
        ['user id']: user,
        password,
        ...other
    } = props
    const hostPart = server || dataSource
    const databasePart = database || initialCatalog
    if (hostPart && databasePart) {
        const [host, port] = hostPart.split(',')
        const options = Object.entries(other).map(([k, v]) => `${k}=${v}`).join('&')
        return options ? [url, user, password, host, port, databasePart, options] : [url, user, password, host, port, databasePart]
    }
    return null
}
