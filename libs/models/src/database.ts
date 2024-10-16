import {z} from "zod";
import zodToJsonSchema from "zod-to-json-schema";
import {DateTime, Millis} from "./common";

// read this file from bottom to the top, to have a top-down read ^^

// TODO:
//   - function to check Database consistency (no relation to non-existing entity, etc)
//   - function to diff two Database
//   - convert Database to Project and the reverse

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
// FIXME: remove unknown from AttributeValue
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
export const AttributesId = z.string() // serialized AttributesRef (EntityId with list of AttributePathId), ex: 'table(id, email)', 'd.c.s.events(payload.address.no, payload.address.street)'
export type AttributesId = z.infer<typeof AttributesId>
export const ConstraintId = z.string() // serialized ConstraintRef (EntityId with ConstraintName), ex: 'table(table_pk)', 'd.c.s.events(event_created_by_fk)'
export type ConstraintId = z.infer<typeof ConstraintId>
export const TypeId = z.string() // serialized TypeRef (type name with namespace), ex: 'public.post_status'
export type TypeId = z.infer<typeof TypeId>
export const RelationId = z.string() // serialized RelationRef link, ex: 'posts(author)->users(id)'
export type RelationId = z.infer<typeof RelationId>

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
export const AttributesRef = EntityRef.extend({ attrs: AttributePath.array() }).strict()
export type AttributesRef = z.infer<typeof AttributesRef>
export const ConstraintRef = EntityRef.extend({ constraint: ConstraintName }).strict()
export type ConstraintRef = z.infer<typeof ConstraintRef>
export const RelationRef = z.object({src: AttributesRef, ref: AttributesRef}).strict()
export type RelationRef = z.infer<typeof RelationRef>
export const TypeRef = Namespace.extend({ type: TypeName }).strict()
export type TypeRef = z.infer<typeof TypeRef>

export const IndexStats = z.object({
    size: z.number().optional(), // used bytes
    scans: z.number().optional(), // number of index scans
    scansLast: DateTime.optional(), // last index scan
}).strict()
export type IndexStats = z.infer<typeof IndexStats>

export const IndexExtra = Extra.and(z.object({
    line: z.number().optional(),
    statement: z.number().optional(),
}))
export type IndexExtra = z.infer<typeof IndexExtra>
export const indexExtraKeys = ['line', 'statement']

export const Check = z.object({
    name: ConstraintName.optional(),
    attrs: AttributePath.array(),
    predicate: z.string(),
    doc: z.string().optional(),
    stats: IndexStats.optional(),
    extra: IndexExtra.optional(),
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
    extra: IndexExtra.optional(),
}).strict()
export type Index = z.infer<typeof Index>

export const PrimaryKey = z.object({
    name: ConstraintName.optional(),
    attrs: AttributePath.array(),
    doc: z.string().optional(),
    stats: IndexStats.optional(),
    extra: IndexExtra.optional(),
}).strict()
export type PrimaryKey = z.infer<typeof PrimaryKey>

export const AttributeTypeKind = z.enum(['string', 'int', 'float', 'bool', 'date', 'time', 'instant', 'period', 'binary', 'uuid', 'json', 'xml', 'array', 'unknown'])
export type AttributeTypeKind = z.infer<typeof AttributeTypeKind>

export const AttributeTypeParsed = z.object({
    full: z.string(),
    kind: AttributeTypeKind,
    size: z.number().optional(),
    variable: z.boolean().optional(),
    encoding: z.string().optional(),
    array: z.boolean().optional(),
}).strict()
export type AttributeTypeParsed = z.infer<typeof AttributeTypeParsed>

export const AttributeStats = z.object({
    nulls: z.number().optional(), // percentage of nulls, between 0 and 1
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

export const AttributeExtra = Extra.and(z.object({
    line: z.number().optional(),
    statement: z.number().optional(),
    autoIncrement: z.null().optional(),
    hidden: z.null().optional(),
    tags: z.string().array().optional(),
    comment: z.string().optional(), // if there is a comment in the attribute line
}))
export type AttributeExtra = z.infer<typeof AttributeExtra>
export const attributeExtraKeys = ['line', 'statement', 'autoIncrement', 'hidden', 'tags', 'comment']
export const attributeExtraProps = ['autoIncrement', 'hidden', 'tags'] // extra keys manually set in properties

export const Attribute: z.ZodType<Attribute> = z.object({
    name: AttributeName,
    type: AttributeType,
    null: z.boolean().optional(), // false when not specified
    gen: z.boolean().optional(), // false when not specified
    default: AttributeValue.optional(),
    attrs: z.lazy(() => Attribute.array().optional()),
    doc: z.string().optional(),
    stats: AttributeStats.optional(),
    extra: AttributeExtra.optional(),
}).strict()
export type Attribute = { // define type explicitly because it's lazy (https://zod.dev/?id=recursive-types)
    name: AttributeName
    type: AttributeType
    null?: boolean | undefined
    gen?: boolean | undefined
    default?: AttributeValue | undefined
    attrs?: Attribute[] | undefined
    doc?: string | undefined
    stats?: AttributeStats | undefined
    extra?: AttributeExtra | undefined
}

export const EntityKind = z.enum(['table', 'view', 'materialized view', 'foreign table'])
export type EntityKind = z.infer<typeof EntityKind>

export const EntityStats = z.object({
    rows: z.number().optional(), // number of rows
    rowsDead: z.number().optional(), // number of dead rows
    size: z.number().optional(), // used bytes
    sizeIdx: z.number().optional(), // used bytes for indexes
    sizeToast: z.number().optional(), // used bytes for toasts
    sizeToastIdx: z.number().optional(), // used bytes for toasts indexes
    scanSeq: z.number().optional(), // number of seq scan
    scanSeqLast: DateTime.optional(),
    scanIdx: z.number().optional(), // number of index scan
    scanIdxLast: DateTime.optional(),
    analyzeLast: DateTime.optional(),
    analyzeLag: z.number().optional(),
    vacuumLast: DateTime.optional(),
    vacuumLag: z.number().optional(),
}).strict()
export type EntityStats = z.infer<typeof EntityStats>

export const EntityExtra = Extra.and(z.object({
    line: z.number().optional(),
    statement: z.number().optional(),
    alias: z.string().optional(),
    color: z.string().optional(),
    tags: z.string().array().optional(),
    comment: z.string().optional(), // if there is a comment in the entity line
}))
export type EntityExtra = z.infer<typeof EntityExtra>
export const entityExtraKeys = ['line', 'statement', 'alias', 'color', 'tags', 'comment']
export const entityExtraProps = ['view', 'color', 'tags'] // extra keys manually set in properties (view is set in props but stored in entity def, not extra ^^)

export const Entity = Namespace.extend({
    name: EntityName,
    kind: EntityKind.optional(), // 'table' when not specified
    def: z.string().optional(), // the query definition for views
    attrs: Attribute.array().optional(),
    pk: PrimaryKey.optional(),
    indexes: Index.array().optional(),
    checks: Check.array().optional(),
    doc: z.string().optional(),
    stats: EntityStats.optional(),
    extra: EntityExtra.optional(),
}).strict()
export type Entity = z.infer<typeof Entity>

export const RelationCardinality = z.enum(['0', '1', 'n'])
export type RelationCardinality = z.infer<typeof RelationCardinality>

export const RelationLink = EntityRef.extend({attrs: AttributePath.array(), cardinality: RelationCardinality.optional()})
export type RelationLink = z.infer<typeof RelationLink>

export const RelationKind = z.enum(['many-to-one', 'one-to-many', 'one-to-one', 'many-to-many'])
export type RelationKind = z.infer<typeof RelationKind>

export const RelationAction = z.enum(['no action', 'set null', 'set default', 'cascade', 'restrict'])
export type RelationAction = z.infer<typeof RelationAction>

export const RelationExtra = Extra.and(z.object({
    line: z.number().optional(),
    statement: z.number().optional(),
    inline: z.boolean().optional(), // when defined within the parent entity
    natural: z.enum(['src', 'ref', 'both']).optional(), // natural join: attributes are not specified
    onUpdate: z.union([RelationAction, z.string()]).optional(),
    onDelete: z.union([RelationAction, z.string()]).optional(),
    srcAlias: z.string().optional(),
    refAlias: z.string().optional(),
    tags: z.string().array().optional(),
    comment: z.string().optional(), // if there is a comment in the relation line
}))
export type RelationExtra = z.infer<typeof RelationExtra>
export const relationExtraKeys = ['line', 'statement', 'inline', 'natural', 'onUpdate', 'onDelete', 'srcAlias', 'refAlias', 'tags', 'comment']
export const relationExtraProps = ['onUpdate', 'onDelete', 'tags'] // extra keys manually set in properties

export const Relation = z.object({
    name: ConstraintName.optional(),
    origin: z.enum(['fk', 'infer-name', 'infer-similar', 'infer-query', 'user']).optional(), // 'fk' when not specified
    src: RelationLink,
    ref: RelationLink,
    polymorphic: z.object({attribute: AttributePath, value: AttributeValue}).optional(),
    doc: z.string().optional(),
    extra: RelationExtra.optional(),
}).strict()
export type Relation = z.infer<typeof Relation>

export const TypeExtra = Extra.and(z.object({
    line: z.number().optional(),
    statement: z.number().optional(),
    inline: z.boolean().optional(), // when defined within the parent entity
    tags: z.string().array().optional(),
    comment: z.string().optional(), // if there is a comment in the type line
}))
export type TypeExtra = z.infer<typeof TypeExtra>
export const typeExtraKeys = ['line', 'statement', 'inline', 'tags', 'comment']
export const typeExtraProps = ['tags'] // extra keys manually set in properties

export const Type = Namespace.extend({
    name: TypeName,
    alias: z.string().optional(),
    values: z.string().array().optional(),
    attrs: Attribute.array().optional(),
    definition: z.string().optional(),
    doc: z.string().optional(),
    extra: TypeExtra.optional(),
}).strict()
export type Type = z.infer<typeof Type>

export const DatabaseKind = z.enum(['bigquery', 'cassandra', 'couchbase', 'db2', 'elasticsearch', 'mariadb', 'mongodb', 'mysql', 'oracle', 'postgres', 'redis', 'snowflake', 'sqlite', 'sqlserver'])
export type DatabaseKind = z.infer<typeof DatabaseKind>

export const DatabaseStats = z.object({
    name: DatabaseName,
    kind: DatabaseKind,
    version: z.string(),
    size: z.number(), // used bytes
    extractedAt: DateTime, // legacy, see extra.createdAt instead
    extractionDuration: Millis, // legacy, see extra.creationTimeMs instead
}).partial().strict()
export type DatabaseStats = z.infer<typeof DatabaseStats>

export const DatabaseExtra = Extra.and(z.object({
    source: z.string().optional(), // what/who created this database, format: `${name} <${version}>` (version is optional, inspired by package.json author)
    createdAt: DateTime.optional(), // when it was created
    creationTimeMs: Millis.optional(), // how long it took to create it
    comments: z.object({line: z.number(), comment: z.string()}).array().optional(), // source line comments, used to generate them back
    namespaces: Namespace.extend({line: z.number(), comment: z.string().optional()}).array().optional(), // source namespace statements, used to generate them back
}))
export type DatabaseExtra = z.infer<typeof DatabaseExtra>
export const databaseExtraKeys = ['source', 'createdAt', 'creationTimeMs', 'comments', 'namespaces']

export const Database = z.object({
    entities: Entity.array().optional(),
    relations: Relation.array().optional(),
    types: Type.array().optional(),
    // functions: z.record(FunctionId, Function.array()).optional(),
    // procedures: z.record(ProcedureId, Procedure.array()).optional(), // parse procedures and list them on tables they use
    // triggers: z.record(TriggerId, Trigger.array()).optional(), // list triggers on tables they belong
    doc: z.string().optional(),
    stats: DatabaseStats.optional(),
    extra: DatabaseExtra.optional(),
}).strict().describe('Database')
export type Database = z.infer<typeof Database>

// keep it sync with backend/priv/static/aml_schema.json (see test)
export const DatabaseSchema = zodToJsonSchema(Database, {
    name: 'Database',
    definitions: {
        DatabaseName, CatalogName, SchemaName, Namespace,
        Entity, EntityRef, EntityName, EntityKind,
        Attribute, AttributeRef, AttributeName, AttributePath, AttributeType, AttributeValue,
        PrimaryKey, Index, Check, ConstraintName,
        Relation, RelationLink, RelationCardinality,
        Type, TypeName,
        Extra, DatabaseExtra, EntityExtra, AttributeExtra, IndexExtra, RelationExtra, TypeExtra
    }
})
