import {z} from "zod";
import {AnyError, indent, joinLast, Logger, plural, stripIndent} from "@azimutt/utils";
import {JsValue, Millis} from "../common";
import {DatabaseUrlParsed} from "../databaseUrl"
import {
    AttributeName,
    AttributeRef,
    AttributeType,
    AttributeValue,
    CatalogName,
    Database,
    DatabaseName,
    EntityName,
    EntityRef,
    SchemaName
} from "../database";

// every connector should implement this interface
// similar to https://github.com/planetscale/database-js?
export interface Connector {
    name: string
    getSchema(application: string, url: DatabaseUrlParsed, opts: ConnectorSchemaOpts): Promise<Database>
    getQueryHistory(application: string, url: DatabaseUrlParsed, opts: ConnectorQueryHistoryOpts): Promise<DatabaseQuery[]>
    execute(application: string, url: DatabaseUrlParsed, query: string, parameters: any[], opts: ConnectorDefaultOpts): Promise<QueryResults>
    analyze(application: string, url: DatabaseUrlParsed, query: string, parameters: any[], opts: ConnectorDefaultOpts): Promise<QueryAnalyze>
    getEntityStats(application: string, url: DatabaseUrlParsed, ref: EntityRef, opts: ConnectorDefaultOpts): Promise<ConnectorEntityStats>
    getAttributeStats(application: string, url: DatabaseUrlParsed, ref: AttributeRef, opts: ConnectorDefaultOpts): Promise<ConnectorAttributeStats>
}

export type ConnectorDefaultOpts = {
    // dependencies
    logger: Logger
    // behavior
    logQueries?: boolean // default: false, log executed queries using the provided logger
}

export type ConnectorScopeOpts = {
    // filters: limit the scope of the extraction
    database?: DatabaseName // export only this database or database pattern (use LIKE if contains %, equality otherwise)
    catalog?: CatalogName // export only this catalog or catalog pattern (use LIKE if contains %, equality otherwise)
    schema?: SchemaName // export only this schema or schema pattern (use LIKE if contains %, equality otherwise)
    entity?: EntityName // export only this entity or entity pattern (use LIKE if contains %, equality otherwise)
}

export type ConnectorSchemaOpts = ConnectorDefaultOpts & ConnectorScopeOpts & {
    // data access: get more interesting result, beware of performance
    sampleSize?: number // default: 100, number of documents used to infer a schema (document databases, json attributes in relational db...)
    inferMixedJson?: string // when inferring JSON, will differentiate documents on this attribute, useful when storing several documents in the same collection in Mongo or Couchbase
    inferJsonAttributes?: boolean // will get sample values from JSON attributes to infer a schema (nested attributes)
    inferPolymorphicRelations?: boolean // will get distinct values from the kind attribute of polymorphic relations to create relations
    inferRelationsFromJoins?: boolean // will fetch historical queries and suggest relations based on joins
    inferPii?: boolean // will fetch sample rows from tables to detect columns with Personal Identifiable Information
    // post analysis:
    inferRelations?: boolean // default: false, infer relations based on attribute names
    // behavior
    ignoreErrors?: boolean // default: false, ignore errors when fetching the schema, just log them
}

export const connectorSchemaOptsDefaults = {
    sampleSize: 100
}

export type ConnectorQueryHistoryOpts = ConnectorDefaultOpts & {
    // filters: limit the scope of the extraction
    user?: string // query stats only from this user or user pattern (use LIKE if contains %, = otherwise)
    database?: DatabaseName // query stats only from this database or database pattern (use LIKE if contains %, = otherwise)
}

// TODO define more generic and meaningful structure
export const DatabaseQuery = z.object({
    id: z.string(), // query id to group duplicates
    user: z.string(), // the user executing the query
    database: DatabaseName, // the database in which the query was executed
    query: z.string(),
    rows: z.number(), // accumulated rows retrieved or affected by the query
    plan: z.object({count: z.number(), minTime: Millis, maxTime: Millis, sumTime: Millis, meanTime: Millis, sdTime: Millis}).strict().optional(),
    exec: z.object({count: z.number(), minTime: Millis, maxTime: Millis, sumTime: Millis, meanTime: Millis, sdTime: Millis}).strict().optional(),
    blocksShared: z.object({read: z.number(), write: z.number(), hit: z.number(), dirty: z.number()}), // data from tables & indexes
    blocksLocal: z.object({read: z.number(), write: z.number(), hit: z.number(), dirty: z.number()}), // data from temporary tables & indexes
    blocksTemp: z.object({read: z.number(), write: z.number()}), // data used for the query
}).strict().describe('DatabaseQuery')
export type DatabaseQuery = z.infer<typeof DatabaseQuery>

export const QueryResultsAttribute = z.object({
    name: z.string(),
    ref: AttributeRef.optional()
}).strict()
export type QueryResultsAttribute = z.infer<typeof QueryResultsAttribute>

export const QueryResults = z.object({
    query: z.string(),
    attributes: QueryResultsAttribute.array(),
    rows: JsValue.array()
}).strict().describe('QueryResults')
export type QueryResults = z.infer<typeof QueryResults>

// TODO
export const QueryAnalyze = z.object({}).strict().describe('QueryAnalyze')
export type QueryAnalyze = z.infer<typeof QueryAnalyze>

export const ConnectorEntityStats = EntityRef.extend({
    rows: z.number(),
    sampleValues: z.record(AttributeValue)
}).strict().describe('ConnectorEntityStats')
export type ConnectorEntityStats = z.infer<typeof ConnectorEntityStats>

export const ConnectorAttributeStatsValue = z.object({
    value: AttributeValue,
    count: z.number()
}).strict()
export type ConnectorAttributeStatsValue = z.infer<typeof ConnectorAttributeStatsValue>

export const ConnectorAttributeStats = AttributeRef.extend({
    type: AttributeType,
    rows: z.number(),
    nulls: z.number(),
    cardinality: z.number(),
    commonValues: ConnectorAttributeStatsValue.array()
}).strict().describe('ConnectorAttributeStats')
export type ConnectorAttributeStats = z.infer<typeof ConnectorAttributeStats>

export const connectorScopeLevels = ['database', 'catalog', 'schema', 'entity'] as const
export type ConnectorScopeNames = {database?: string, catalog?: string, schema?: string, entity?: string}

export function formatConnectorScope(names: ConnectorScopeNames, opts: ConnectorScopeOpts): string {
    const filters = connectorScopeLevels
        .map(key => [names[key], opts[key]])
        .filter((v): v is [string, string] => !!v[0] && !!v[1])
        .map(([name, opt]) => `${opt.includes('%') ? plural(name) : name} '${opt}'`)
    if (filters.length > 0) {
        return joinLast(filters, ', ', ' and ')
    } else {
        return ''
    }
}

export const logQueryIfNeeded = <U>(
    id: number,
    name: string | undefined,
    sql: string,
    parameters: any[],
    exec: (sql: string, parameters: any[]) => Promise<U>,
    count: (res: U) => number,
    {logger, logQueries}: ConnectorDefaultOpts
): Promise<U> => {
    if (logQueries) {
        const start = Date.now()
        const queryId = `#${id}${name ? ' ' + name : ''}`
        logger.log(`${queryId} exec:\n${indent(stripIndent(sql))}`)
        const res = exec(sql, parameters)
        res.then(
            r => logger.log(`${queryId} success: ${count(r)} rows in ${Date.now() - start} ms`),
            e => logger.log(`${queryId} failure: ${e} in ${Date.now() - start} ms`)
        )
        return res
    } else {
        return exec(sql, parameters)
    }
}

export function isPolymorphic(attr: AttributeName, entityAttrs: AttributeName[]): boolean {
    return ['type', 'class', 'kind'].some(suffix => {
        if (attr.endsWith(suffix)) {
            const related = attr.slice(0, -suffix.length) + 'id'
            return entityAttrs.some(c => c === related)
        } else if (attr.endsWith(suffix.toUpperCase())) {
            const related = attr.slice(0, -suffix.length) + 'ID'
            return entityAttrs.some(c => c === related)
        } else if (attr.endsWith(suffix.charAt(0).toUpperCase() + suffix.slice(1))) {
            const related = attr.slice(0, -suffix.length) + 'Id'
            return entityAttrs.some(c => c === related)
        } else {
            return false
        }
    })
}

export function queryError(name: string | undefined, sql: string, err: AnyError): Error {
    const formattedSql = stripIndent(sql)
    if (typeof err === 'object' && err !== null) {
        return new Error(
            err.constructor.name +
            'code' in err && err.code ? ` ${err.code}` : '' +
            name ? ` on query ${name}` : '' +
            'message' in err && err.message ? `: ${err.message}` : '' +
                `\nQuery: ${formattedSql}`)
    } else if (err) {
        return new Error(`Error ${JSON.stringify(err)}\n on '${formattedSql}'`)
    } else {
        return new Error(`Error on '${formattedSql}'`)
    }
}

export function handleError<T>(msg: string, onError: T, {logger, ignoreErrors}: ConnectorSchemaOpts) {
    return (err: any): Promise<T> => {
        if (ignoreErrors) {
            logger.warn(`${msg}. Ignoring...`)
            return Promise.resolve(onError)
        } else {
            return Promise.reject(err)
        }
    }
}
