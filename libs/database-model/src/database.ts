import {z} from "zod";
import zodToJsonSchema from "zod-to-json-schema";

// read this file from bottom to the top, to have a top-down read ^^

// TODO:
//   - function to check Database consistency (no relation to non-existing entity, etc)
//   - function to diff two Database
//   - function to merge two Database
//   - convert Database to Project and the reverse
//   - parseEntityId(EntityId): EntityRef, parseColumnId(ColumnId): ColumnRef, parseColumnType(ColumnType): ColumnTypeParsed

export const DatabaseName = z.string()
export type DatabaseName = z.infer<typeof DatabaseName>
export const CatalogName = z.string()
export type CatalogName = z.infer<typeof CatalogName>
export const SchemaName = z.string()
export type SchemaName = z.infer<typeof SchemaName>
export const EntityName = z.string()
export type EntityName = z.infer<typeof EntityName>
export const ColumnName = z.string()
export type ColumnName = z.infer<typeof ColumnName>
export const ColumnPath = z.string() // column name with nested columns: ex: 'column.nested_column', 'payload.address.street'
export type ColumnPath = z.infer<typeof ColumnPath>
export const ColumnType = z.string() // TODO: add ColumnTypeParsed?
export type ColumnType = z.infer<typeof ColumnType>
export const ColumnValue = z.union([z.string(), z.number(), z.boolean(), z.date(), z.null(), z.unknown()])
export type ColumnValue = z.infer<typeof ColumnValue>
export const ConstraintName = z.string()
export type ConstraintName = z.infer<typeof ConstraintName>
export const TypeName = z.string()
export type TypeName = z.infer<typeof TypeName>

export const NamespaceId = z.string() // serialized Namespace, ex: 'database.catalog.schema', 'public'
export type NamespaceId = z.infer<typeof NamespaceId>
export const EntityId = z.string() // serialized EntityRef (entity name with namespace), ex: 'database.catalog.schema.table', 'public.users'
export type EntityId = z.infer<typeof EntityId>
export const ColumnId = z.string() // serialized ColumnRef (EntityId with ColumnPath), ex: 'table(id)', 'd.c.s.events(payload.address.no)'
export type ColumnId = z.infer<typeof ColumnId>

export const JsValueLiteral = z.union([z.string(), z.number(), z.boolean(), z.null()])
export type JsValueLiteral = z.infer<typeof JsValueLiteral>
export const JsValue: z.ZodType<JsValue> = z.lazy(() => z.union([JsValueLiteral, z.array(JsValue), z.record(JsValue)]))
export type JsValue = JsValueLiteral | { [key: string]: JsValue } | JsValue[] // define type explicitly because it's lazy (https://zod.dev/?id=recursive-types)

export const Extra = z.record(z.any())
export type Extra = z.infer<typeof Extra>

export const Namespace = z.object({
    database: DatabaseName,
    catalog: CatalogName,
    schema: SchemaName,
}).partial().strict()
export type Namespace = z.infer<typeof Namespace>

export const EntityRef = Namespace.merge(z.object({ entity: EntityName })).strict()
export type EntityRef = z.infer<typeof EntityRef>
export const ColumnRef = EntityRef.merge(z.object({ column: ColumnPath })).strict()
export type ColumnRef = z.infer<typeof ColumnRef>

export const IndexStats = z.object({
    size: z.number().optional(), // used bytes
    scans: z.number().optional(), // number of index scans
}).strict()
export type IndexStats = z.infer<typeof IndexStats>

export const Check = z.object({
    columns: ColumnPath.array(),
    predicate: z.string(),
    name: ConstraintName.optional(),
    doc: z.string().optional(),
    stats: IndexStats.optional(),
    extra: Extra.optional()
}).strict()
export type Check = z.infer<typeof Check>

export const Index = z.object({
    columns: ColumnPath.array(),
    name: ConstraintName.optional(),
    unique: z.boolean().optional(), // false when not specified
    partial: z.string().optional(),
    definition: z.string().optional(),
    doc: z.string().optional(),
    stats: IndexStats.optional(),
    extra: Extra.optional()
}).strict()
export type Index = z.infer<typeof Index>

export const PrimaryKey = z.object({
    columns: ColumnPath.array(),
    name: ConstraintName.optional(),
    doc: z.string().optional(),
    stats: IndexStats.optional(),
    extra: Extra.optional()
}).strict()
export type PrimaryKey = z.infer<typeof PrimaryKey>

export const ColumnTypeKind = z.enum(['text', 'int', 'float', 'bool', 'uuid', 'date', 'time', 'instant', 'binary', 'json', 'array', 'unknown'])
export type ColumnTypeKind = z.infer<typeof ColumnTypeKind>

export const ColumnTypeParsed = z.object({
    full: z.string(), // TODO: same as `DatabaseUrlParsed`, rename to `original`, `raw` or `formatted`?
    kind: ColumnTypeKind,
    size: z.number().optional(),
    encoding: z.string().optional(),
    array: z.boolean().optional(),
}).strict()
export type ColumnTypeParsed = z.infer<typeof ColumnTypeParsed>

export const ColumnStats = z.object({
    nulls: z.number().optional(), // percentage of nulls
    avgBytes: z.number().optional(), // average bytes for a value
    cardinality: z.number().optional(), // number of different values
    commonValues: z.object({
        value: ColumnValue,
        freq: z.number()
    }).strict().array().optional(),
    histogram: ColumnValue.array().optional(),
    min: ColumnValue.optional(),
    max: ColumnValue.optional(),
}).strict()
export type ColumnStats = z.infer<typeof ColumnStats>

export const Column: z.ZodType<Column> = z.object({
    name: ColumnName,
    type: ColumnType,
    nullable: z.boolean().optional(), // false when not specified
    generated: z.boolean().optional(), // false when not specified
    default: ColumnValue.optional(),
    values: ColumnValue.array().optional(),
    columns: z.lazy(() => Column.array().optional()),
    doc: z.string().optional(),
    stats: ColumnStats.optional(),
    extra: Extra.optional()
}).strict()
export type Column = { // define type explicitly because it's lazy (https://zod.dev/?id=recursive-types)
    name: ColumnName
    type: ColumnType
    nullable?: boolean | undefined
    generated?: boolean | undefined
    default?: ColumnValue | undefined
    values?: ColumnValue[] | undefined
    columns?: Column[] | undefined
    doc?: string | undefined
    stats?: ColumnStats | undefined
    extra?: Extra | undefined
}

export const EntityKind = z.enum(['table', 'view', 'materialized view', 'foreign table'])
export type EntityKind = z.infer<typeof EntityKind>

export const EntityStats = z.object({
    rows: z.number().optional(), // number of rows
    size: z.number().optional(), // used bytes
    sizeIdx: z.number().optional(), // used bytes for indexes
    sizeToast: z.number().optional(), // used bytes for toasts
    sizeToastIdx: z.number().optional(), // used bytes for toasts indexes
    seq_scan: z.number().optional(), // number of seq scan
    idx_scan: z.number().optional(), // number of index scan
}).strict()
export type EntityStats = z.infer<typeof EntityStats>

export const Entity = Namespace.merge(z.object({
    name: EntityName,
    kind: EntityKind.optional(), // 'table' when not specified
    definition: z.string().optional(), // the query definition for views
    columns: Column.array(),
    primaryKey: PrimaryKey.optional(),
    indexes: Index.array().optional(),
    checks: Check.array().optional(),
    doc: z.string().optional(),
    stats: EntityStats.optional(),
    extra: Extra.optional()
})).strict()
export type Entity = z.infer<typeof Entity>

export const RelationKind = z.enum(['many-to-one', 'one-to-many', 'one-to-one', 'many-to-many'])
export type RelationKind = z.infer<typeof RelationKind>

export const Relation = Namespace.merge(z.object({
    src: EntityRef,
    ref: EntityRef,
    columns: z.object({src: ColumnPath, ref: ColumnPath}).array(),
    polymorphic: z.object({column: ColumnPath, value: ColumnValue}).optional(),
    name: ConstraintName.optional(),
    kind: RelationKind.optional(), // 'many-to-one' when not specified
    doc: z.string().optional(),
    extra: Extra.optional()
})).strict()
export type Relation = z.infer<typeof Relation>

export const Type = Namespace.merge(z.object({
    name: TypeName,
    values: z.string().array().optional(),
    columns: Column.array().optional(),
    definition: z.string().optional(),
    doc: z.string().optional(),
    extra: Extra.optional()
})).strict()
export type Type = z.infer<typeof Type>

export const DatabaseKind = z.enum(['cassandra', 'couchbase', 'db2', 'elasticsearch', 'mariadb', 'mongodb', 'mysql', 'oracle', 'postgres', 'redis', 'snowflake', 'sqlite', 'sqlserver'])
export type DatabaseKind = z.infer<typeof DatabaseKind>

export const DatabaseStats = z.object({
    size: z.number().optional(), // used bytes
}).strict()
export type DatabaseStats = z.infer<typeof DatabaseStats>

export const Database = z.object({
    entities: Entity.array(),
    relations: Relation.array(),
    types: Type.array(),
    // functions: Function.array(),
    // procedures: Procedure.array(),
    // triggers: Trigger.array(),
    doc: z.string().optional(),
    stats: DatabaseStats.optional(),
    extra: Extra.optional(),
}).partial().strict()
export type Database = z.infer<typeof Database>

export const DatabaseSchema = zodToJsonSchema(Database, {
    name: 'Database',
    definitions: {
        DatabaseName, CatalogName, SchemaName, Namespace,
        Entity, EntityRef, EntityName, EntityKind,
        Column, ColumnRef, ColumnName, ColumnPath, ColumnType, ColumnValue,
        PrimaryKey, Index, Check,
        Relation, ConstraintName, RelationKind,
        Type, TypeName,
        Extra
    }
})
