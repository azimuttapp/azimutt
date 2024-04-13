import {z} from "zod";

const jsValueLiteral = z.union([z.string(), z.number(), z.boolean(), z.null()])
type JsValueLiteral = z.infer<typeof jsValueLiteral>
export type JsValue = JsValueLiteral | { [key: string]: JsValue } | JsValue[]
export const JsValue: z.ZodType<JsValue> = z.lazy(() => z.union([jsValueLiteral, z.array(JsValue), z.record(JsValue)]))

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
export type ColumnPathStr = string
export const ColumnPathStr = z.string()
export const columnPathSeparator = ":"
export type ColumnType = string
export const ColumnType = z.string()
export type ColumnValue = string | number | boolean | Date | null | unknown
export const ColumnValue = z.union([z.string(), z.number(), z.boolean(), z.date(), z.null(), JsValue])
export type ColumnRef = { table: TableId, column: ColumnPathStr }
export const ColumnRef = z.object({table: TableId, column: ColumnPathStr}).strict()

export function parseTableId(id: TableId): { schema: SchemaName, table: TableName } {
    const parts = id.split('.')
    return parts.length === 2 ? {schema: parts[0], table: parts[1]} : {schema: '', table: id}
}

// use `.nullish()` instead of `.optional()` because the backend return nulls :/
export type AzimuttSchemaName = string
export const AzimuttSchemaName = z.string()
export type AzimuttTableName = string
export const AzimuttTableName = z.string()
export type AzimuttColumnName = string
export const AzimuttColumnName = z.string()
export type AzimuttColumnType = string
export const AzimuttColumnType = z.string()
export const azimuttColumnTypeUnknown: AzimuttColumnType = 'unknown'
export type AzimuttColumnValue = string
export const AzimuttColumnValue = z.string()
export type AzimuttPrimaryKey = { name?: string | null, columns: AzimuttColumnName[] }
export const AzimuttPrimaryKey = z.object({name: z.string().nullish(), columns: AzimuttColumnName.array()}).strict()
export type AzimuttUnique = { name?: string | null, columns: AzimuttColumnName[], definition?: string | null }
export const AzimuttUnique = z.object({
    name: z.string().nullish(),
    columns: AzimuttColumnName.array(),
    definition: z.string().nullish()
}).strict()
export type AzimuttIndex = { name?: string | null, columns: AzimuttColumnName[], definition?: string | null }
export const AzimuttIndex = z.object({
    name: z.string().nullish(),
    columns: AzimuttColumnName.array(),
    definition: z.string().nullish()
}).strict()
export type AzimuttCheck = { name?: string | null, columns: AzimuttColumnName[], predicate?: string | null }
export const AzimuttCheck = z.object({
    name: z.string().nullish(),
    columns: AzimuttColumnName.array(),
    predicate: z.string().nullish()
}).strict()
export type AzimuttColumn = {
    name: AzimuttColumnName
    type: AzimuttColumnType
    nullable?: boolean | null
    default?: AzimuttColumnValue | null
    comment?: string | null
    values?: string[] | null
    columns?: AzimuttColumn[] | null
}
export const AzimuttColumn: z.ZodType<AzimuttColumn> = z.object({
    name: AzimuttColumnName,
    type: AzimuttColumnType,
    nullable: z.boolean().nullish(),
    default: AzimuttColumnValue.nullish(),
    comment: z.string().nullish(),
    values: z.string().array().nullish(),
    columns: z.lazy(() => AzimuttColumn.array().nullish())
}).strict()
// TODO: mutualise with LegacyProjectTable in libs/models/src/legacy/legacyProject.ts:244?
export type AzimuttTable = {
    schema: AzimuttSchemaName
    table: AzimuttTableName
    columns: AzimuttColumn[]
    view?: boolean | null
    primaryKey?: AzimuttPrimaryKey | null
    uniques?: AzimuttUnique[] | null
    indexes?: AzimuttIndex[] | null
    checks?: AzimuttCheck[] | null
    comment?: string | null
}
export const AzimuttTable = z.object({
    schema: AzimuttSchemaName,
    table: AzimuttTableName,
    columns: AzimuttColumn.array(),
    view: z.boolean().nullish(),
    primaryKey: AzimuttPrimaryKey.nullish(),
    uniques: AzimuttUnique.array().nullish(),
    indexes: AzimuttIndex.array().nullish(),
    checks: AzimuttCheck.array().nullish(),
    comment: z.string().nullish()
}).strict()
export type AzimuttColumnRef = { schema: AzimuttSchemaName, table: AzimuttTableName, column: AzimuttColumnName }
export const AzimuttColumnRef = z.object({
    schema: AzimuttSchemaName,
    table: AzimuttTableName,
    column: AzimuttColumnName
}).strict()
export type AzimuttRelation = { name: string, src: AzimuttColumnRef, ref: AzimuttColumnRef }
export const AzimuttRelation = z.object({name: z.string(), src: AzimuttColumnRef, ref: AzimuttColumnRef}).strict()
type AzimuttTypeContent = { values: string[] | null } | { definition: string }
const AzimuttTypeContent = z.union([
    z.object({values: z.string().array().nullable()}),
    z.object({definition: z.string()})
])
export type AzimuttType = { schema: AzimuttSchemaName, name: string } & AzimuttTypeContent
export const AzimuttType = z.object({
    schema: AzimuttSchemaName,
    name: z.string()
}).and(AzimuttTypeContent)
export type AzimuttSchema = { tables: AzimuttTable[], relations: AzimuttRelation[], types?: AzimuttType[] | null }
export const AzimuttSchema = z.object({
    tables: AzimuttTable.array(),
    relations: AzimuttRelation.array(),
    types: AzimuttType.array().nullish()
}).strict()


export type TableSampleValues = { [column: string]: ColumnValue }
export const TableSampleValues = z.record(ColumnValue)

// keep sync with frontend/src/Models/Project/TableStats.elm
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

// keep sync with frontend/src/Models/Project/ColumnStats.elm
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
