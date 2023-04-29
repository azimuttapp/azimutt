import {z} from "zod";

const literalSchema = z.union([z.string(), z.number(), z.boolean(), z.null()])
type Literal = z.infer<typeof literalSchema>
type Json = Literal | { [key: string]: Json } | Json[]
export const Json: z.ZodType<Json> = z.lazy(() => z.union([literalSchema, z.array(Json), z.record(Json)]))

export type TableId = string
export const TableId = z.string()
export type SchemaName = string
export const SchemaName = z.string()
export type TableName = string
export const TableName = z.string()
export type ColumnId = string
export const ColumnId = z.string()
export type ColumnName = string
export const ColumnName = z.string()
export type ColumnType = string
export const ColumnType = z.string()
export type ColumnValue = string | number | boolean | Date | null | unknown
export const ColumnValue = z.union([z.string(), z.number(), z.boolean(), z.date(), z.null(), Json])
export type ColumnRef = { table: TableId, column: ColumnName }
export const ColumnRef = z.object({table: TableId, column: ColumnName}).strict()

export function parseTableId(id: TableId): { schema: SchemaName, table: TableName } {
    const parts = id.split('.')
    return parts.length === 2 ? {schema: parts[0], table: parts[1]} : {schema: '', table: id}
}

export type AzimuttSchema = { tables: AzimuttTable[], relations: AzimuttRelation[], types?: AzimuttType[] }
export type AzimuttTable = {
    schema: AzimuttSchemaName,
    table: AzimuttTableName,
    columns: AzimuttColumn[],
    view?: boolean,
    primaryKey?: AzimuttPrimaryKey,
    uniques?: AzimuttUnique[],
    indexes?: AzimuttIndex[],
    checks?: AzimuttCheck[],
    comment?: string
}
export type AzimuttColumn = {
    name: AzimuttColumnName,
    type: AzimuttColumnType,
    nullable?: boolean,
    default?: AzimuttColumnValue,
    comment?: string
}
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

export type TableSampleValues = { [column: string]: ColumnValue }
export const TableSampleValues = z.record(ColumnValue)

// keep sync with backend/lib/azimutt/analyzer/table_stats.ex & frontend/src/Models/Project/TableStats.elm
export interface TableStats {
    schema: SchemaName | null
    table: TableName
    rows: number
    sample_values: TableSampleValues
}

export const TableStats = z.object({
    schema: SchemaName.nullable(),
    table: TableName,
    rows: z.number(),
    sample_values: TableSampleValues
}).strict()

export type ColumnCommonValue = { value: ColumnValue, count: number }
export const ColumnCommonValue = z.object({value: ColumnValue, count: z.number()})

// keep sync with backend/lib/azimutt/analyzer/column_stats.ex & frontend/src/Models/Project/ColumnStats.elm
export interface ColumnStats {
    schema: SchemaName | null
    table: TableName
    column: ColumnName
    type: ColumnType
    rows: number
    nulls: number
    cardinality: number
    common_values: ColumnCommonValue[]
}

export const ColumnStats = z.object({
    schema: SchemaName.nullable(),
    table: TableName,
    column: ColumnName,
    type: ColumnType,
    rows: z.number(),
    nulls: z.number(),
    cardinality: z.number(),
    common_values: ColumnCommonValue.array()
}).strict()
