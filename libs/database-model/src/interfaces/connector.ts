import {indent, Logger, stripIndent} from "@azimutt/utils";
import {Millis} from "../common";
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
    JsValue,
    SchemaName
} from "../database";

// every connector should implement this interface
export interface Connector {
    name: string
    getSchema(application: string, url: DatabaseUrlParsed, opts: ConnectorSchemaOpts): Promise<Database>
    getQueryHistory(application: string, url: DatabaseUrlParsed, opts: ConnectorQueryHistoryOpts): Promise<DatabaseQuery[]>
    execute(application: string, url: DatabaseUrlParsed, query: string, parameters: any[], opts: ConnectorDefaultOpts): Promise<QueryResults>
    analyze(application: string, url: DatabaseUrlParsed, query: string, parameters: any[], opts: ConnectorDefaultOpts): Promise<QueryAnalyze>
    // TODO: needs to be challenged
    getEntityStats(application: string, url: DatabaseUrlParsed, ref: EntityRef, opts: ConnectorDefaultOpts): Promise<ConnectorEntityStats>
    getAttributeStats(application: string, url: DatabaseUrlParsed, ref: AttributeRef, opts: ConnectorDefaultOpts): Promise<ConnectorAttributeStats>
}

export type ConnectorDefaultOpts = {
    // dependencies
    logger: Logger
    // behavior
    logQueries?: boolean // default: false, log executed queries using the provided logger
}

export type ConnectorSchemaOpts = ConnectorDefaultOpts & {
    // filters: limit the scope of the extraction
    database?: DatabaseName // export only this database or database pattern (use LIKE if contains %, equality otherwise)
    catalog?: CatalogName // export only this catalog or catalog pattern (use LIKE if contains %, equality otherwise)
    schema?: SchemaName // export only this schema or schema pattern (use LIKE if contains %, equality otherwise)
    entity?: EntityName // export only this entity or entity pattern (use LIKE if contains %, equality otherwise)
    // data access: get more interesting result, beware of performance
    sampleSize?: number // default: 100, number of documents used to infer a schema (document databases, json attributes in relational db...)
    inferMixedJson?: string // when inferring JSON, will differentiate documents on this attribute, useful when storing several documents in the same collection in Mongo or Couchbase
    inferJsonAttributes?: boolean // will get sample values from JSON attributes to infer a schema (nested attributes)
    inferPolymorphicRelations?: boolean // will get distinct values from the kind attribute of polymorphic relations to create relations
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
export type DatabaseQuery = {
    id: string // query id to group duplicates
    user: string // the user executing the query
    database: DatabaseName // the database in which the query was executed
    query: string
    rows: number // accumulated rows retrieved or affected by the query
    plan?: {count: number, minTime: Millis, maxTime: Millis, sumTime: Millis, meanTime: Millis, sdTime: Millis} // query planning
    exec?: {count: number, minTime: Millis, maxTime: Millis, sumTime: Millis, meanTime: Millis, sdTime: Millis} // query execution
    blocksShared: {read: number, write: number, hit: number, dirty: number} // data from tables & indexes
    blocksLocal: {read: number, write: number, hit: number, dirty: number} // data from temporary tables & indexes
    blocksTemp: {read: number, write: number} // data used for the query
}

export type QueryResults = {
    query: string
    attributes: QueryResultsAttribute[]
    rows: JsValue[]
}

export type QueryResultsAttribute = { name: string, ref?: AttributeRef }

export type QueryAnalyze = string

export type ConnectorEntityStats = EntityRef & {
    rows: number
    sampleValues: { [attribute: string]: AttributeValue }
}

export type ConnectorAttributeStats = AttributeRef & {
    type: AttributeType
    rows: number
    nulls: number
    cardinality: number
    commonValues: ConnectorAttributeStatsValue[]
}

export type ConnectorAttributeStatsValue = { value: AttributeValue, count: number }

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
