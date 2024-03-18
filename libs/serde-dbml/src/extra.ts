import {z} from "zod";
import {SchemaName, EntityRef} from "@azimutt/database-model";

export const Group = z.object({
    schema: SchemaName.optional(),
    name: z.string(),
    entities: EntityRef.array()
}).strict()
export type Group = z.infer<typeof Group>

export const DatabaseExtra = z.object({
    source: z.string(), // which parser generated the database (and may have stored its extension values), ex: 'dbml'
    groups: Group.array() // group of tables to show in the diagram
}).partial().optional()
export type DatabaseExtra = z.infer<typeof DatabaseExtra>

export const EntityExtra = z.object({
    alias: z.string(), // table alias
    color: z.string() // table color for the diagram
}).partial().optional()
export type EntityExtra = z.infer<typeof EntityExtra>

export const AttributeExtra = z.object({
    increment: z.boolean(), // true when the attribute is an auto-incremented primary key
    defaultType: z.string() // if the default value has a specific type, like 'expression'
}).partial().optional()
export type AttributeExtra = z.infer<typeof AttributeExtra>

export const IndexExtra = z.object({
    attrTypes: z.record(z.enum(['column', 'expression'])) // when index attributes has specific type, like 'expression'
}).partial().optional()
export type IndexExtra = z.infer<typeof IndexExtra>

export const RelationExtra = z.object({
    onDelete: z.string(), // action to perform when the referenced row is deleted
    onUpdate: z.string() // action to perform when the referenced row is updated
}).partial().optional()
export type RelationExtra = z.infer<typeof RelationExtra>

export const TypeExtra = z.object({
    notes: z.record(z.string()) // to keep notes for each type value
}).partial().optional()
export type TypeExtra = z.infer<typeof TypeExtra>
