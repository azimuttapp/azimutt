import {filterValues} from "./object";

export type DbKind = 'mongodb' | 'postgres'
export type DbUrl = { full: string, kind?: DbKind, user?: string, pass?: string, host?: string, port?: number, db?: string, options?: string }

// vertically align regexes with variable names ^^
const mongoRegex = /mongodb(?:\+srv)?:\/\/(?:([^:]+):([^@]+)@)?([^:/?]+)(?::(\d+))?(?:\/([^?]+))?(?:\?(.+))?/
const p = /^(?:jdbc:)?postgres(?:ql)?:\/\/(?:([^:]+):([^@]+)@)?([^:/?]+)(?::(\d+))?(?:\/([^?]+))?$/

export function parseUrl(url: string): DbUrl {
    const mongo = url.match(mongoRegex)
    const postgres = mongo ? null : url.match(p)
    if (mongo) {
        const [, user, pass, host, port, db, options] = mongo
        const opts = {kind: 'mongodb', user, pass, host, port: port ? parseInt(port) : undefined, db, options}
        return {...filterValues(opts, v => v !== undefined), full: url}
    } else if (postgres) {
        const [, user, pass, host, port, db] = postgres
        const opts = {kind: 'postgres', user, pass, host, port: port ? parseInt(port) : undefined, db}
        return {...filterValues(opts, v => v !== undefined), full: url}
    } else {
        return {full: url}
    }
}

export type AzimuttSchema = { tables: AzimuttTable[], relations: AzimuttRelation[], types?: AzimuttType[] }
export type AzimuttTable = { schema: AzimuttSchemaName, table: AzimuttTableName, columns: AzimuttColumn[], view?: boolean, primaryKey?: AzimuttPrimaryKey, uniques?: AzimuttUnique[], indexes?: AzimuttIndex[], checks?: AzimuttCheck[], comment?: string }
export type AzimuttColumn = { name: AzimuttColumnName, type: AzimuttColumnType, nullable?: boolean, default?: AzimuttColumnValue, comment?: string }
export type AzimuttPrimaryKey = { name?: string, columns: AzimuttColumnName[] }
export type AzimuttUnique = { name?: string, columns: AzimuttColumnName[], definition?: string }
export type AzimuttIndex = { name?: string, columns: AzimuttColumnName[], definition?: string }
export type AzimuttCheck = { name?: string, columns: AzimuttColumnName[], predicate?: string }
export type AzimuttRelation = { name: string, src: AzimuttColumnRef, ref: AzimuttColumnRef }
export type AzimuttColumnRef = { schema: AzimuttSchemaName, table: AzimuttTableName, column: AzimuttColumnName }
export type AzimuttType = { schema: AzimuttSchemaName, name: string } & ({ values: string[] } | { definition: string })
export type AzimuttSchemaName = string
export type AzimuttTableName = string
export type AzimuttColumnName = string
export type AzimuttColumnType = string
export type AzimuttColumnValue = string
