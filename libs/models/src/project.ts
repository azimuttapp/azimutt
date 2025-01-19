import {z} from "zod";
import {Color, Markdown, Uuid} from "./common";
import {AttributePathId, Database, DatabaseKind, EntityId, NamespaceId, Relation} from "./database";

// FIXME: Work In Progress
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

// SourceAttribute: firstSeen
// SourceEntity: firstSeen

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
    enabled: z.boolean().optional(), // TODO: move to layout
    createdAt: z.date(),
    updatedAt: z.date(),
}).strict()
export type Source = z.infer<typeof Source>

/*
 * Layout part
 */

// entity, row, memo, link...
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

/*
 * Documentation part
 */

export const TagName = z.string()
export type TagName = z.infer<typeof TagName>
export const Tag = z.object({
    name: z.string(),
    description: z.string().optional(),
    color: Color
}).strict()
export type Tag = z.infer<typeof Tag>

// user properties allows to fill structured documentation, for example: ownership, lineage, data quality, expiration, link to resources...
export const UserPropertyName = z.string()
export type UserPropertyName = z.infer<typeof UserPropertyName>
export const UserPropertyKind = z.enum([
    'string', // single line text
    'text', // multiline text, formatted with markdown
    'enum', // pre-defined set of values
    'url',
    'email',
    'phone',
    'date',
    'bool', // checkbox
    'number',
    'rating', // 5 stars rating
    'progress', // 0-100% progress bar
    'user', // user uuid
    'entity', // entity ref
    'attribute', // attribute ref
    'row' // row ref (table with primary key)
])
export type UserPropertyKind = z.infer<typeof UserPropertyKind>
export const UserProperty = z.object({
    name: UserPropertyName,
    description: z.string().optional(),
    // icon: z.enum(['???']).optional(),
    kind: UserPropertyKind,
    on: z.enum(['entity', 'attribute']).array(),
    multi: z.boolean().optional(),
    enum_values: z.object({
        name: z.string(),
        description: z.string().optional(),
        color: Color
    }).strict().array().optional(),
    string_values: z.string().array().optional(),
    validation_regex: z.string().optional()
}).strict()
export type UserProperty = z.infer<typeof UserProperty>
export const UserPropertyValue = z.union([z.string(), z.string().array()])
export type UserPropertyValue = z.infer<typeof UserPropertyValue>

export const AttributeDoc = z.object({
    defaultShow: z.boolean().optional(), // true when not specified
    defaultPos: z.number().optional(),
    alias: z.string().optional(),
    doc: Markdown.optional(),
    tags: TagName.array().optional(),
    props: z.record(UserPropertyName, UserPropertyValue).optional()
}).strict()
export type AttributeDoc = z.infer<typeof AttributeDoc>

export const EntityDoc = z.object({
    alias: z.string().optional(),
    doc: Markdown.optional(),
    tags: TagName.array().optional(),
    color: Color.optional(),
    props: z.record(UserPropertyName, UserPropertyValue).optional(),
    attrs: z.record(AttributePathId, AttributeDoc).optional(),
}).strict()
export type EntityDoc = z.infer<typeof EntityDoc>


export const ProjectStats = z.object({
    shownEntities: z.record(EntityId, z.number()).optional(), // get rough idea of entity popularity
    shownLayouts: z.record(LayoutName, z.number()).optional(), // get rough idea of layout popularity
}).strict()
export type ProjectStats = z.infer<typeof ProjectStats>

export const Project = z.object({
    id: ProjectId,
    slug: ProjectSlug,
    name: ProjectName,
    // storage
    // version
    sources: Source.array(),
    layouts: z.record(LayoutName, Layout.array()),
    metadata: z.record(EntityId, EntityDoc).optional(),
    // queries
    stats: ProjectStats.optional(),
    // createdAt
    // updatedAt
}).strict()
export type Project = z.infer<typeof Project>


// stored only in the user browser
export const ProjectUserStats = z.object({
    shownEntities: z.record(EntityId, z.number()).optional(),
    shownLayouts: z.record(LayoutName, z.number()).optional(),
    queryHistory: z.object({
        source: SourceId,
        query: z.string(),
        ranAt: z.date(),
    }).array().optional(),
}).strict()
export type ProjectUserStats = z.infer<typeof ProjectUserStats>
