import {ColumnName, ColumnType, ColumnValue, SchemaName, TableName} from "./project";
import {z} from "zod";

export interface TableStats {
    schema: SchemaName | null
    table: TableName
    rows: number
}

export const TableStats = z.object({
    schema: SchemaName.nullable(),
    table: TableName,
    rows: z.number()
}).strict()

export interface ColumnStats {
    schema: SchemaName | null
    table: TableName
    column: ColumnName
    rows: number
    nulls: number
    cardinality: number
    common_values: {value: ColumnValue, count: number}[]
}

export const ColumnStats = z.object({
    schema: SchemaName.nullable(),
    table: TableName,
    column: ColumnName,
    type: ColumnType,
    rows: z.number(),
    nulls: z.number(),
    cardinality: z.number(),
    common_values: z.object({value: ColumnValue, count: z.number()}).array()
}).strict()
