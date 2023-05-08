// every connector should implement this interface
import {z} from "zod";
import {Logger} from "@azimutt/utils";
import {DatabaseUrlParsed} from "./url";
import {AzimuttSchema, ColumnRef, ColumnStats, JsValue, TableId, TableStats} from "./schema";

export interface Connector {
    name: string
    // use `$1`, `$2`... placeholders in the query to inject parameters
    getSchema(application: string, url: DatabaseUrlParsed, opts: SchemaOpts): Promise<AzimuttSchema>
    getTableStats(application: string, url: DatabaseUrlParsed, id: TableId): Promise<TableStats>
    getColumnStats(application: string, url: DatabaseUrlParsed, ref: ColumnRef): Promise<ColumnStats>
    query(application: string, url: DatabaseUrlParsed, query: string, parameters: any[]): Promise<DatabaseQueryResults>
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

export interface SchemaOpts {
    logger: Logger
    schema?: string // export only a single schema, bucket or database
    sampleSize?: number // default: 100, number of documents used to infer the schema (document databases, json columns in relational db...)
    inferRelations?: boolean // default: false, infer relations based on column names
}
