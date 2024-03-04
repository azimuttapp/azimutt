// every connector should implement this interface
import {z} from "zod";
import {Logger} from "@azimutt/utils";
import {DatabaseUrlParsed} from "./url";
import {AzimuttSchema, ColumnRef, ColumnStats, JsValue, TableId, TableStats} from "./schema";

export interface Connector {
    name: string
    // use `$1`, `$2`... placeholders in the query to inject parameters
    getSchema(application: string, url: DatabaseUrlParsed, opts: ConnectorOpts & SchemaOpts): Promise<AzimuttSchema>
    getTableStats(application: string, url: DatabaseUrlParsed, id: TableId, opts: ConnectorOpts): Promise<TableStats>
    getColumnStats(application: string, url: DatabaseUrlParsed, ref: ColumnRef, opts: ConnectorOpts): Promise<ColumnStats>
    query(application: string, url: DatabaseUrlParsed, query: string, parameters: any[], opts: ConnectorOpts): Promise<DatabaseQueryResults>
}

export interface ConnectorOpts {
    logger: Logger
    logQueries?: boolean // default: false, print executed queries in the console
}

export interface SchemaOpts {
    schema?: string // export only a single schema, bucket or database
    mixedCollection?: string // attribute name if collections have mixed documents identified by kind
    sampleSize?: number // default: 100, number of documents used to infer the schema (document databases, json columns in relational db...)
    inferRelations?: boolean // default: false, infer relations based on column names
    ignoreErrors?: boolean // default: false, ignore errors when fetching the schema
}

export interface DatabaseQueryResultsColumn {
    name: string
    ref?: ColumnRef
}

export const DatabaseQueryResultsColumn = z.object({
    name: z.string(),
    ref: ColumnRef.optional(),
}).strict()

export interface DatabaseQueryResults {
    query: string
    columns: DatabaseQueryResultsColumn[]
    rows: JsValue[]
}

export const DatabaseQueryResults = z.object({
    query: z.string(),
    columns: DatabaseQueryResultsColumn.array(),
    rows: JsValue.array(),
}).strict()

export const logQueryIfNeeded = <U>(id: number, name: string | undefined, sql: string, parameters: any[], exec: (sql: string, parameters: any[]) => Promise<U>, count: (res: U) => number, logger: Logger, logQueries: boolean): Promise<U> => {
    if (logQueries) {
        const start = Date.now()
        name ? logger.log(`#${id} exec: ${name}\n${sql}`) : logger.log(`#${id} exec: ${sql}`)
        const res = exec(sql, parameters)
        res.then(
            r => logger.log(`#${id} success: ${count(r)} rows in ${Date.now() - start} ms`),
            e => logger.log(`#${id} failure: ${e} in ${Date.now() - start} ms`)
        )
        return res
    } else {
        return exec(sql, parameters)
    }
}

export function isPolymorphicColumn(column: string, columns: string[]): boolean {
    return ['type', 'class', 'kind'].some(suffix => {
        if (column.endsWith(suffix)) {
            const related = column.slice(0, -suffix.length) + 'id'
            return columns.some(c => c === related)
        } else if (column.endsWith(suffix.toUpperCase())) {
            const related = column.slice(0, -suffix.length) + 'ID'
            return columns.some(c => c === related)
        } else if (column.endsWith(suffix.charAt(0).toUpperCase() + suffix.slice(1))) {
            const related = column.slice(0, -suffix.length) + 'Id'
            return columns.some(c => c === related)
        } else {
            return false
        }
    })
}
