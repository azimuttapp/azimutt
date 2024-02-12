import {z} from "zod";
import zodToJsonSchema from "zod-to-json-schema";

// read this file from bottom to top ^^
// you will have a top-down read, but the definitions needs to be bottom-up

export const DatabaseName = z.string()
export type DatabaseName = z.infer<typeof DatabaseName>
export const CatalogName = z.string()
export type CatalogName = z.infer<typeof CatalogName>
export const SchemaName = z.string()
export type SchemaName = z.infer<typeof SchemaName>
export const TableName = z.string()
export type TableName = z.infer<typeof TableName>
export const TableId = z.string() // serialized TableRef (table name with namespace), ex: 'database.catalog.schema.table', 'public.users'
export type TableId = z.infer<typeof TableId>
export const ColumnName = z.string()
export type ColumnName = z.infer<typeof ColumnName>
export const ColumnPath = z.string() // column name with nested columns: ex: 'column.nested_column', 'payload.address.street'
export type ColumnPath = z.infer<typeof ColumnPath>
export const ColumnId = z.string() // serialized ColumnRef (TableId with ColumnPath), ex: 'table(id)', 'd.c.s.events(payload.address.no)'
export type ColumnId = z.infer<typeof ColumnId>
export const ColumnType = z.string() // TODO: add ColumnTypeParsed?
export type ColumnType = z.infer<typeof ColumnType>
export const ColumnValue = z.union([z.string(), z.number(), z.boolean(), z.date(), z.null(), z.unknown()])
export type ColumnValue = z.infer<typeof ColumnValue>
export const ConstraintName = z.string()
export type ConstraintName = z.infer<typeof ConstraintName>
export const TypeName = z.string()
export type TypeName = z.infer<typeof TypeName>

export const JsValueLiteral = z.union([z.string(), z.number(), z.boolean(), z.null()])
export type JsValueLiteral = z.infer<typeof JsValueLiteral>
export const JsValue: z.ZodType<JsValue> = z.lazy(() => z.union([JsValueLiteral, z.array(JsValue), z.record(JsValue)]))
export type JsValue = JsValueLiteral | { [key: string]: JsValue } | JsValue[] // define type explicitly because it's lazy (https://zod.dev/?id=recursive-types)

export const Extensions = z.record(z.any())
export type Extensions = z.infer<typeof Extensions>

export const Namespace = z.object({
    database: DatabaseName,
    catalog: CatalogName,
    schema: SchemaName,
}).partial().strict()
export type Namespace = z.infer<typeof Namespace>

export const Type = Namespace.merge(z.object({
    name: TypeName,
    values: z.string().array().optional(),
    definition: z.string().optional(),
    comment: z.string().optional(),
    extensions: Extensions.optional()
})).strict()
export type Type = z.infer<typeof Type>

export const TableRef = Namespace.merge(z.object({ table: TableName })).strict()
export type TableRef = z.infer<typeof TableRef>
export const ColumnRef = TableRef.merge(z.object({ column: ColumnPath })).strict()
export type ColumnRef = z.infer<typeof ColumnRef>

export const RelationKind = z.enum(['many-to-one', 'one-to-many', 'one-to-one', 'many-to-many'])
export type RelationKind = z.infer<typeof RelationKind>

export const Relation = Namespace.merge(z.object({
    src: TableRef,
    ref: TableRef,
    columns: z.object({src: ColumnPath, ref: ColumnPath}).array(),
    polymorphic: z.object({column: ColumnPath, value: ColumnValue}).optional(),
    name: ConstraintName.optional(),
    kind: RelationKind.optional(), // 'many-to-one' when not specified
    comment: z.string().optional(),
    extensions: Extensions.optional()
})).strict()
export type Relation = z.infer<typeof Relation>

export const Check = z.object({
    columns: ColumnPath.array(),
    predicate: z.string(),
    name: ConstraintName.optional(),
    comment: z.string().optional(),
    extensions: Extensions.optional()
}).strict()
export type Check = z.infer<typeof Check>

export const Index = z.object({
    columns: ColumnPath.array(),
    name: ConstraintName.optional(),
    unique: z.boolean().optional(), // false when not specified
    partial: z.string().optional(),
    definition: z.string().optional(),
    comment: z.string().optional(),
    extensions: Extensions.optional()
}).strict()
export type Index = z.infer<typeof Index>

export const PrimaryKey = z.object({
    columns: ColumnPath.array(),
    name: ConstraintName.optional(),
    comment: z.string().optional(),
    extensions: Extensions.optional()
}).strict()
export type PrimaryKey = z.infer<typeof PrimaryKey>

export const Column: z.ZodType<Column> = z.object({
    name: ColumnName,
    type: ColumnType,
    nullable: z.boolean().optional(), // false when not specified
    generated: z.boolean().optional(), // false when not specified
    default: ColumnValue.optional(),
    values: ColumnValue.array().optional(),
    columns: z.lazy(() => Column.array().optional()),
    comment: z.string().optional(),
    extensions: Extensions.optional()
}).strict()
export type Column = { // define type explicitly because it's lazy (https://zod.dev/?id=recursive-types)
    name: ColumnName
    type: ColumnType
    nullable?: boolean
    generated?: boolean
    default?: ColumnValue
    values?: ColumnValue[]
    columns?: Column[]
    comment?: string
    extensions?: Extensions
}

export const TableKind = z.enum(['table', 'view', 'materialized view', 'foreign table'])
export type TableKind = z.infer<typeof TableKind>

export const Table = Namespace.merge(z.object({
    name: TableName,
    kind: TableKind.optional(), // 'table' when not specified
    columns: Column.array(),
    primaryKey: PrimaryKey.optional(),
    indexes: Index.array().optional(),
    checks: Check.array().optional(),
    comment: z.string().optional(),
    extensions: Extensions.optional()
})).strict()
export type Table = z.infer<typeof Table>

export const Database = z.object({
    tables: Table.array(),
    relations: Relation.array(),
    types: Type.array(),
    // functions: Function.array(),
    // procedures: Procedure.array(),
    // triggers: Trigger.array(),
    comment: z.string(),
    extensions: Extensions
}).partial().strict()
export type Database = z.infer<typeof Database>

export const DatabaseSchema = zodToJsonSchema(Database, {
    name: 'Database',
    definitions: {
        Namespace, DatabaseName, CatalogName, SchemaName,
        Table, TableRef, TableName, TableKind, Column, ColumnRef, ColumnName, ColumnPath, ColumnType, ColumnValue, PrimaryKey, Index, Check,
        Relation, ConstraintName, RelationKind,
        Type, TypeName,
        Extensions
    }
})
