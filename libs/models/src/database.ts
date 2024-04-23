import {z} from "zod";
import zodToJsonSchema from "zod-to-json-schema";
import {DateTime, Millis} from "./common";

// read this file from bottom to the top, to have a top-down read ^^

// TODO:
//   - function to check Database consistency (no relation to non-existing entity, etc)
//   - function to diff two Database
//   - function to merge two Database
//   - convert Database to Project and the reverse
//   - parseAttributeType(AttributeType): AttributeTypeParsed

export const DatabaseName = z.string()
export type DatabaseName = z.infer<typeof DatabaseName>
export const CatalogName = z.string()
export type CatalogName = z.infer<typeof CatalogName>
export const SchemaName = z.string()
export type SchemaName = z.infer<typeof SchemaName>
export const EntityName = z.string()
export type EntityName = z.infer<typeof EntityName>
export const AttributeName = z.string()
export type AttributeName = z.infer<typeof AttributeName>
export const AttributePath = AttributeName.array()
export type AttributePath = z.infer<typeof AttributePath>
export const AttributeType = z.string()
export type AttributeType = z.infer<typeof AttributeType>
export const AttributeValue = z.union([z.string(), z.number(), z.boolean(), z.date(), z.null(), z.unknown()])
export type AttributeValue = z.infer<typeof AttributeValue>
export const ConstraintName = z.string()
export type ConstraintName = z.infer<typeof ConstraintName>
export const TypeName = z.string()
export type TypeName = z.infer<typeof TypeName>

export const NamespaceId = z.string() // serialized Namespace, ex: 'database.catalog.schema', 'public'
export type NamespaceId = z.infer<typeof NamespaceId>
export const EntityId = z.string() // serialized EntityRef (entity name with namespace), ex: 'database.catalog.schema.table', 'public.users'
export type EntityId = z.infer<typeof EntityId>
export const AttributePathId = z.string() // serialized AttributePath for nested attributes: ex: 'attribute.nested_attribute', 'payload.address.street'
export type AttributePathId = z.infer<typeof AttributePathId>
export const AttributeId = z.string() // serialized AttributeRef (EntityId with AttributePathId), ex: 'table(id)', 'd.c.s.events(payload.address.no)'
export type AttributeId = z.infer<typeof AttributeId>
export const TypeId = z.string() // serialized TypeRef (type name with namespace), ex: 'public.post_status'
export type TypeId = z.infer<typeof TypeId>

export const Extra = z.record(z.any())
export type Extra = z.infer<typeof Extra>

export const Namespace = z.object({
    database: DatabaseName,
    catalog: CatalogName,
    schema: SchemaName,
}).partial().strict()
export type Namespace = z.infer<typeof Namespace>

export const EntityRef = Namespace.extend({ entity: EntityName }).strict()
export type EntityRef = z.infer<typeof EntityRef>
export const AttributeRef = EntityRef.extend({ attribute: AttributePath }).strict()
export type AttributeRef = z.infer<typeof AttributeRef>
export const TypeRef = Namespace.extend({ type: TypeName }).strict()
export type TypeRef = z.infer<typeof TypeRef>

export const IndexStats = z.object({
    size: z.number().optional(), // used bytes
    scans: z.number().optional(), // number of index scans
}).strict()
export type IndexStats = z.infer<typeof IndexStats>

export const Check = z.object({
    name: ConstraintName.optional(),
    attrs: AttributePath.array(),
    predicate: z.string(),
    doc: z.string().optional(),
    stats: IndexStats.optional(),
    extra: Extra.optional()
}).strict()
export type Check = z.infer<typeof Check>

export const Index = z.object({
    name: ConstraintName.optional(),
    attrs: AttributePath.array(),
    unique: z.boolean().optional(), // false when not specified
    partial: z.string().optional(), // false when not specified
    definition: z.string().optional(),
    doc: z.string().optional(),
    stats: IndexStats.optional(),
    extra: Extra.optional()
}).strict()
export type Index = z.infer<typeof Index>

export const PrimaryKey = z.object({
    name: ConstraintName.optional(),
    attrs: AttributePath.array(),
    doc: z.string().optional(),
    stats: IndexStats.optional(),
    extra: Extra.optional()
}).strict()
export type PrimaryKey = z.infer<typeof PrimaryKey>

export const AttributeTypeKind = z.enum(['text', 'int', 'float', 'bool', 'uuid', 'date', 'time', 'instant', 'binary', 'json', 'array', 'unknown'])
export type AttributeTypeKind = z.infer<typeof AttributeTypeKind>

export const AttributeTypeParsed = z.object({
    full: z.string(),
    kind: AttributeTypeKind,
    size: z.number().optional(),
    encoding: z.string().optional(),
    array: z.boolean().optional(),
}).strict()
export type AttributeTypeParsed = z.infer<typeof AttributeTypeParsed>

export const AttributeStats = z.object({
    nulls: z.number().optional(), // percentage of nulls
    bytesAvg: z.number().optional(), // average bytes for a value
    cardinality: z.number().optional(), // number of different values
    commonValues: z.object({
        value: AttributeValue,
        freq: z.number()
    }).strict().array().optional(),
    distinctValues: AttributeValue.array().optional(),
    histogram: AttributeValue.array().optional(),
    min: AttributeValue.optional(),
    max: AttributeValue.optional(),
}).strict()
export type AttributeStats = z.infer<typeof AttributeStats>

export const Attribute: z.ZodType<Attribute> = z.object({
    pos: z.number(),
    name: AttributeName,
    type: AttributeType,
    null: z.boolean().optional(), // false when not specified
    gen: z.boolean().optional(), // false when not specified
    default: AttributeValue.optional(),
    attrs: z.lazy(() => z.record(AttributeName, Attribute).optional()),
    doc: z.string().optional(),
    stats: AttributeStats.optional(),
    extra: Extra.optional()
}).strict()
export type Attribute = { // define type explicitly because it's lazy (https://zod.dev/?id=recursive-types)
    pos: number
    name: AttributeName
    type: AttributeType
    null?: boolean | undefined
    gen?: boolean | undefined
    default?: AttributeValue | undefined
    attrs?: { [name: AttributeName]: Attribute } | undefined
    doc?: string | undefined
    stats?: AttributeStats | undefined
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
    scanSeq: z.number().optional(), // number of seq scan
    scanSeqLast: DateTime.optional(),
    scanIdx: z.number().optional(), // number of index scan
    scanIdxLast: DateTime.optional(),
    analyzeLast: DateTime.optional(),
    vacuumLast: DateTime.optional(),
}).strict()
export type EntityStats = z.infer<typeof EntityStats>

export const Entity = Namespace.extend({
    name: EntityName,
    kind: EntityKind.optional(), // 'table' when not specified
    def: z.string().optional(), // the query definition for views
    attrs: z.record(AttributeName, Attribute),
    pk: PrimaryKey.optional(),
    indexes: Index.array().optional(),
    checks: Check.array().optional(),
    doc: z.string().optional(),
    stats: EntityStats.optional(),
    extra: Extra.optional()
}).strict()
export type Entity = z.infer<typeof Entity>

export const RelationKind = z.enum(['many-to-one', 'one-to-many', 'one-to-one', 'many-to-many'])
export type RelationKind = z.infer<typeof RelationKind>

export const Relation = z.object({
    name: ConstraintName.optional(),
    kind: RelationKind.optional(), // 'many-to-one' when not specified
    origin: z.enum(['fk', 'infer-name', 'infer-similar', 'infer-query', 'user']).optional(), // 'fk' when not specified
    src: EntityRef,
    ref: EntityRef,
    attrs: z.object({src: AttributePath, ref: AttributePath}).array(),
    polymorphic: z.object({attribute: AttributePath, value: AttributeValue}).optional(),
    doc: z.string().optional(),
    extra: Extra.optional()
}).strict()
export type Relation = z.infer<typeof Relation>

export const Type = Namespace.extend({
    name: TypeName,
    values: z.string().array().optional(),
    attrs: Attribute.array().optional(),
    definition: z.string().optional(),
    doc: z.string().optional(),
    extra: Extra.optional()
}).strict()
export type Type = z.infer<typeof Type>

export const DatabaseKind = z.enum(['bigquery', 'cassandra', 'couchbase', 'db2', 'elasticsearch', 'mariadb', 'mongodb', 'mysql', 'oracle', 'postgres', 'redis', 'snowflake', 'sqlite', 'sqlserver'])
export type DatabaseKind = z.infer<typeof DatabaseKind>

export const DatabaseStats = z.object({
    name: DatabaseName,
    kind: DatabaseKind,
    version: z.string(),
    doc: z.string(),
    extractedAt: DateTime, // when the database was extracted
    extractionDuration: Millis,
    // url? host? options?
    size: z.number(), // used bytes
}).partial().strict()
export type DatabaseStats = z.infer<typeof DatabaseStats>

export const Database = z.object({
    entities: z.record(EntityId, Entity),
    relations: z.record(EntityId, z.record(EntityId, Relation.array())),
    types: z.record(TypeId, Type),
    // functions: z.record(FunctionId, Function.array()),
    // procedures: z.record(ProcedureId, Procedure.array()),
    // triggers: z.record(TriggerId, Trigger.array()),
    doc: z.string(),
    stats: DatabaseStats,
    extra: Extra,
}).partial().strict().describe('Database')
export type Database = z.infer<typeof Database>

export const DatabaseSchema = zodToJsonSchema(Database, {
    name: 'Database',
    definitions: {
        DatabaseName, CatalogName, SchemaName, Namespace,
        Entity, EntityRef, EntityName, EntityKind,
        Attribute, AttributeRef, AttributeName, AttributePath, AttributeType, AttributeValue,
        PrimaryKey, Index, Check,
        Relation, ConstraintName, RelationKind,
        Type, TypeName,
        Extra
    }
})
