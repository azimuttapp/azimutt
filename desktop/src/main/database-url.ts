import {filterValues} from "./utils/object";

export type DbKind = 'mongodb' | 'couchbase' | 'postgres'
export type DbUrl = { full: string, kind?: DbKind, user?: string, pass?: string, host?: string, port?: number, db?: string, options?: string }

// vertically align regexes with variable names ^^
const mongoRegex = /mongodb(?:\+srv)?:\/\/(?:([^:]+):([^@]+)@)?([^:/?]+)(?::(\d+))?(?:\/([^?]+))?(?:\?(.+))?/
const p = /^(?:jdbc:)?postgres(?:ql)?:\/\/(?:([^:]+):([^@]+)@)?([^:/?]+)(?::(\d+))?(?:\/([^?]+))?$/
const couchbaseRegexps = /^couchbases?:\/\/(?:([^:]+):([^@]+)@)?([^:/?]+)(?::(\d+))?(?:\/([^?]+))?$/

export function parseUrl(url: string): DbUrl {
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
