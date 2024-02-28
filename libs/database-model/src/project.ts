import {z} from "zod";
import {Markdown, Uuid} from "./common";
import {ColumnPath, Database, DatabaseKind, EntityId, NamespaceId, Relation} from "./database";

// read this file from bottom to the top, to have a top-down read ^^

export const ProjectId = Uuid
export type ProjectId = z.infer<typeof ProjectId>
export const ProjectSlug = z.string()
export type ProjectSlug = z.infer<typeof ProjectSlug>
export const ProjectName = z.string()
export type ProjectName = z.infer<typeof ProjectName>
export const SourceId = Uuid
export type SourceId = z.infer<typeof SourceId>
export const SourceName = z.string()
export type SourceName = z.infer<typeof SourceName>
export const SourceKind = z.enum(['Connection', 'SQL', 'AML', 'DBML', 'Prisma', 'JSON'])
export type SourceKind = z.infer<typeof SourceKind>
export const LayoutName = z.string()
export type LayoutName = z.infer<typeof LayoutName>
export const Tag = z.string()
export type Tag = z.infer<typeof Tag>


export const Source = z.object({
    id: SourceId,
    name: SourceName,
    kind: SourceKind,
    engine: DatabaseKind.optional(),
    url: z.string().optional(), // db url, file url or file path
    database: Database,
    content: z.string().optional(),
    inferredRelations: Relation.array().optional(),
    ignoredRelations: Relation.array().optional(),
    addedRelations: Relation.array().optional(),
    namespaceMappings: z.record(NamespaceId, NamespaceId).optional(), // change namespaces when merging sources together
    enabled: z.boolean().optional(),
    createdAt: z.date(),
    updatedAt: z.date(),
}).strict()
export type Source = z.infer<typeof Source>


// entity, row, note...
export const LayoutItem = z.object({

})
export type LayoutItem = z.infer<typeof LayoutItem>

export const Layout = z.object({
    name: LayoutName,
    items: LayoutItem.array(),
    itemSeq: z.number().optional()
    // groups
}).strict()
export type Layout = z.infer<typeof Layout>


export const ColumnDoc = z.object({
    alias: z.string().optional(),
    content: Markdown.optional(),
    tags: Tag.array().optional(),
}).strict()
export type ColumnDoc = z.infer<typeof ColumnDoc>

export const EntityDoc = z.object({
    alias: z.string().optional(),
    content: Markdown.optional(),
    tags: Tag.array().optional(),
    columns: z.record(ColumnPath, ColumnDoc).optional(),
}).strict()
export type EntityDoc = z.infer<typeof EntityDoc>


export const Project = z.object({
    id: ProjectId,
    slug: ProjectSlug,
    name: ProjectName,
    // storage
    // version
    sources: Source.array(),
    layouts: z.record(LayoutName, Layout.array()),
    metadata: z.record(EntityId, EntityDoc).optional(),
    // createdAt
    // updatedAt
}).strict()
export type Project = z.infer<typeof Project>
