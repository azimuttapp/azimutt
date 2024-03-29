import {z} from "zod";
import {filterValues} from "@azimutt/utils";
import {DatabaseKind} from "./database";

export const DatabaseUrl = z.string()
export type DatabaseUrl = z.infer<typeof DatabaseUrl>
export const DatabaseUrlParsed = z.object({
    full: z.string(), // TODO: rename to `original`, `raw` or `formatted`?
    kind: DatabaseKind.optional(), // TODO: add `unknown` and make to required?
    user: z.string().optional(),
    pass: z.string().optional(),
    host: z.string().optional(),
    port: z.number().optional(),
    db: z.string().optional(),
    options: z.string().optional(), // TODO: review this to make sure it's the best (use Record<string, string> instead?)
}).strict()
export type DatabaseUrlParsed = z.infer<typeof DatabaseUrlParsed>

// vertically align regexes with variable names ^^
const bq = /^(?:jdbc:)?bigquery:\/\/(?:([^:]+):([^@]*)@)?(?:https:\/\/)?([^:/?&]+)?(?::(\d+))?(?:\/([^?]+))?(?:\?(.+))?$/
const couchbaseRegexxxxxxxxxxx = /^couchbases?:\/\/(?:([^:]+):([^@]*)@)?([^:/?&]+)(?::(\d+))?(?:\/([^?]+))?(?:\?(.+))?$/
const mariadbRegexxxxxxx = /^(?:jdbc:)?mariadb:\/\/(?:([^:]+):([^@]*)@)?([^:/?&]+)(?::(\d+))?(?:\/([^?]+))?(?:\?(.+))?$/
const mongoRegexxxxxxxxxx = /mongodb(?:\+srv)?:\/\/(?:([^:]+):([^@]*)@)?([^:/?&]+)(?::(\d+))?(?:\/([^?]+))?(?:\?(.+))?$/
const mysqlRegexxxxxxxxxxx = /^(?:jdbc:)?mysql:\/\/(?:([^:]+):([^@]*)@)?([^:/?&]+)(?::(\d+))?(?:\/([^?]+))?(?:\?(.+))?$/
const postgresRe = /^(?:jdbc:)?postgres(?:ql)?:\/\/(?:([^:]+):([^@]*)@)?([^:/?&]+)(?::(\d+))?(?:\/([^?]+))?(?:\?(.+))?$/
const sqlserver = /^(?:jdbc:)?sqlserver(?:ql)?:\/\/(?:([^:]+):([^@]*)@)?([^:/?&]+)(?::(\d+))?(?:\/([^?]+))?(?:\?(.+))?$/
const snowflakeRegexxx = /^(?:jdbc:)?snowflake:\/\/(?:([^:]+):([^@]*)@)?([^:/?&]+)(?::(\d+))?(?:\/([^?]+))?(?:\?(.+))?$/
const snowflakeRegexxxxxxxxxxxxxx = /^https:\/\/(?:([^:]+):([^@]*)@)?(.+?(?:\.privatelink)?\.snowflakecomputing\.com)(?::(\d+))?(?:\/([^?]+))?$/

export function parseDatabaseUrl(rawUrl: DatabaseUrl): DatabaseUrlParsed {
    const url = rawUrl.trim()

    const bigqueryMatches = url.match(bq)
    if (bigqueryMatches) {
        const kind: DatabaseKind = 'bigquery'
        const [, user, pass, host, port, db, optionsStr] = bigqueryMatches
        const {email: user2, key: pass2, project: db2, ...opts} = parseDatabaseOptions(optionsStr)
        const options = formatDatabaseOptions(opts)
        const values = {kind, user: user || user2, pass: pass || pass2, host, port: port ? parseInt(port) : undefined, db: db || db2, options}
        return {...filterValues(values, v => v !== undefined), full: url}
    }

    const couchbaseMatches = url.match(couchbaseRegexxxxxxxxxxx)
    if (couchbaseMatches) {
        const kind: DatabaseKind = 'couchbase'
        const [, user, pass, host, port, db, options] = couchbaseMatches
        const opts = {kind, user, pass, host, port: port ? parseInt(port) : undefined, db, options}
        return {...filterValues(opts, v => v !== undefined), full: url}
    }

    const mariadbMatches = url.match(mariadbRegexxxxxxx)
    if (mariadbMatches) {
        const kind: DatabaseKind = 'mariadb'
        const [, user, pass, host, port, db, options] = mariadbMatches
        const opts = {kind, user, pass, host, port: port ? parseInt(port) : undefined, db, options}
        return {...filterValues(opts, v => v !== undefined), full: url}
    }

    const mongodbMatches = url.match(mongoRegexxxxxxxxxx)
    if (mongodbMatches) {
        const kind: DatabaseKind = 'mongodb'
        const [, user, pass, host, port, db, options] = mongodbMatches
        const opts = {kind, user, pass, host, port: port ? parseInt(port) : undefined, db, options}
        return {...filterValues(opts, v => v !== undefined), full: url}
    }

    const mysqlMatches = url.match(mysqlRegexxxxxxxxxxx)
    if (mysqlMatches) {
        const kind: DatabaseKind = 'mysql'
        const [, user, pass, host, port, db, options] = mysqlMatches
        const opts = {kind, user, pass, host, port: port ? parseInt(port) : undefined, db, options}
        return {...filterValues(opts, v => v !== undefined), full: url}
    }

    const postgresMatches = url.match(postgresRe)
    if (postgresMatches) {
        const kind: DatabaseKind = 'postgres'
        const [, user, pass, host, port, db, options] = postgresMatches
        const opts = {kind, user, pass, host, port: port ? parseInt(port) : undefined, db, options}
        return {...filterValues(opts, v => v !== undefined), full: url}
    }

    const snowflakeMatches = url.match(snowflakeRegexxx) || url.match(snowflakeRegexxxxxxxxxxxxxx)
    if (snowflakeMatches) {
        const kind: DatabaseKind = 'snowflake'
        const [, user, pass, host, port, db, optionsStr] = snowflakeMatches
        const {db: db2, user: user2, ...opts} = parseDatabaseOptions(optionsStr)
        const options = formatDatabaseOptions(opts)
        const values = {kind, user: user || user2, pass, host, port: port ? parseInt(port) : undefined, db: db || db2, options}
        return {...filterValues(values, v => v !== undefined), full: url}
    }

    const sqlserverMatches = url.match(sqlserver) || parseSqlServerUrl(url)
    if (sqlserverMatches) {
        const kind: DatabaseKind = 'sqlserver'
        const [, user, pass, host, port, db, options] = sqlserverMatches
        const opts = {kind, user, pass, host, port: port ? parseInt(port) : undefined, db, options}
        return {...filterValues(opts, v => v !== undefined), full: url}
    }

    return {full: url}
}

export function parseDatabaseOptions(options: string | undefined): Record<string, string> {
    return Object.fromEntries((options || '')
        .split('&')
        .filter(o => !!o)
        .map(o => o.split('='))
    )
}

export function formatDatabaseOptions(opts: Record<string, string>): string | undefined {
    return Object.entries(opts).filter(([k, _]) => k).map(([k, v]) => `${k}=${v}`).join('&') || undefined
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
