import {z} from "zod"
import {AttributePath, EntityName, EntityRef, Namespace, SchemaName} from "@azimutt/database-model";

// https://www.postgresql.org/docs/current/sql-select.html
// https://dev.mysql.com/doc/refman/8.3/en/select.html

const ColumnRef = Namespace.merge(z.object({
    kind: z.literal('column'),
    table: EntityName.optional(),
    column: AttributePath
})).strict()

const Expression = z.object({
    kind: z.literal('expression'),
    text: z.string(),
    columns: ColumnRef.array().optional()
})

const Wildcard = z.object({
    kind: z.literal('wildcard'),
    table: EntityName.optional(),
    schema: EntityName.optional(),
})

// should handle `*`, `table.*`, `table.column`, `table.column AS alias`, `lower(column) AS alias`, `column->>'nested' AS alias`
export const Column = z.object({
    content: z.discriminatedUnion('kind', [Wildcard, ColumnRef, Expression]),
    alias: z.string().optional(),
    name: z.string() // computed, either from alias, column name or expression
})
export type Column = z.infer<typeof Column>

// the select result
const Result = z.object({
    columns: Column.array(),
    distinct: z.boolean().optional()
})

export const From: z.ZodType<From> = z.object({
    schema: SchemaName.optional(),
    table: EntityRef.optional(),
    select: z.lazy(() => Select.optional()),
    alias: z.string().optional()
}).strict()
export type From = { // define type explicitly because it's lazy (https://zod.dev/?id=recursive-types)
    table?: EntityRef | undefined;
    select?: Select | undefined;
    alias?: string | undefined;
}

export const Select = z.object({
    command: z.literal('SELECT'),
    language: z.literal('DML'),
    operation: z.literal('read'),
    result: Result,
    from: From,
    joins: From.array().optional()
    // where
    // groupBy
    // having
    // orderBy
    // offset
    // limit
}).strict()
export type Select = z.infer<typeof Select>
