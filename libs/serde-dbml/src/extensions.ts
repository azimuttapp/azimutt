import {z} from "zod";
import {SchemaName, TableRef} from "@azimutt/database-model";

export const Group = z.object({
    schema: SchemaName.optional(),
    name: z.string(),
    tables: TableRef.array()
}).strict()
export type Group = z.infer<typeof Group>

export const DatabaseExtensions = z.object({
    source: z.string(), // which parser generated the database (and may have stored its extension values), ex: 'dbml'
    groups: Group.array() // group of tables to show in the diagram
}).partial().optional()
export type DatabaseExtensions = z.infer<typeof DatabaseExtensions>

export const TableExtensions = z.object({
    alias: z.string(), // table alias
    color: z.string() // table color for the diagram
}).partial().optional()
export type TableExtensions = z.infer<typeof TableExtensions>

export const ColumnExtensions = z.object({
    increment: z.boolean(), // true when the column is an auto-incremented primary key
    defaultType: z.string() // if the default value has a specific type, like 'expression'
}).partial().optional()
export type ColumnExtensions = z.infer<typeof ColumnExtensions>

export const IndexExtensions = z.object({
    columnTypes: z.record(z.enum(['column', 'expression'])) // when index columns has specific type, like 'expression'
}).partial().optional()
export type IndexExtensions = z.infer<typeof IndexExtensions>

export const RelationExtensions = z.object({
    onDelete: z.string(), // action to perform when the referenced row is deleted
    onUpdate: z.string() // action to perform when the referenced row is updated
}).partial().optional()
export type RelationExtensions = z.infer<typeof RelationExtensions>

export const TypeExtensions = z.object({
    notes: z.record(z.string()) // to keep notes for each type value
}).partial().optional()
export type TypeExtensions = z.infer<typeof TypeExtensions>
