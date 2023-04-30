import {z} from "zod";
import {filterValues} from "@azimutt/utils";

export type DatabaseUrl = string
export const DatabaseUrl = z.string()
export type DatabaseUrlParsed = { full: string, kind?: DatabaseKind, user?: string, pass?: string, host?: string, port?: number, db?: string, options?: string }
export type DatabaseKind = 'couchbase' | 'mongodb' | 'postgres'

// vertically align regexes with variable names ^^
const mongoRegex = /mongodb(?:\+srv)?:\/\/(?:([^:]+):([^@]+)@)?([^:/?]+)(?::(\d+))?(?:\/([^?]+))?(?:\?(.+))?/
const p = /^(?:jdbc:)?postgres(?:ql)?:\/\/(?:([^:]+):([^@]+)@)?([^:/?]+)(?::(\d+))?(?:\/([^?]+))?$/
const couchbaseRegexps = /^couchbases?:\/\/(?:([^:]+):([^@]+)@)?([^:/?]+)(?::(\d+))?(?:\/([^?]+))?$/

export function parseDatabaseUrl(url: DatabaseUrl): DatabaseUrlParsed {
    const mongo = url.match(mongoRegex)
    const couchbase = mongo ? null : url.match(couchbaseRegexps)
    const postgres = mongo || couchbase ? null : url.match(p)
    if (mongo) {
        const [, user, pass, host, port, db, options] = mongo
        const opts = {kind: 'mongodb', user, pass, host, port: port ? parseInt(port) : undefined, db, options}
        return {...filterValues(opts, v => v !== undefined), full: url}
    } else if (couchbase) {
        const [, user, pass, host, port, db] = couchbase
        const opts = {kind: 'couchbase', user, pass, host, port: port ? parseInt(port) : undefined, db}
        return {...filterValues(opts, v => v !== undefined), full: url}
    } else if (postgres) {
        const [, user, pass, host, port, db] = postgres
        const opts = {kind: 'postgres', user, pass, host, port: port ? parseInt(port) : undefined, db}
        return {...filterValues(opts, v => v !== undefined), full: url}
    } else {
        return {full: url}
    }
}
