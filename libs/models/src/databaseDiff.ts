import {z} from "zod";
import {anySame, arraySame, diffBy, removeEmpty, removeUndefined} from "@azimutt/utils";
import {
    Attribute,
    AttributeName,
    AttributeType,
    AttributeValue,
    Database,
    Entity,
    EntityKind,
    EntityName,
    Extra,
    Namespace,
    Type,
    TypeName
} from "./database";
import {entityToId, typeToId, typeToNamespace} from "./databaseUtils";

// FIXME: Work In Progress
// cf https://github.com/andreyvit/json-diff

export const ArrayDiff = <T, U>(schema: z.ZodType<T>, schemaDiff: z.ZodType<U>): z.ZodType<ArrayDiff<T, U>> => z.object({
    unchanged: schema.and(z.object({i: z.number()})).array(), // both present but same
    updated: schemaDiff.array(), // both present but different
    created: schema.and(z.object({i: z.number()})).array(), // after only
    deleted: schema.and(z.object({i: z.number()})).array(), // before only
}).strict()
export type ArrayDiff<T, U> = {unchanged: (T & {i: number})[], updated: U[], created: (T & {i: number})[], deleted: (T & {i: number})[]}

export const ValueDiff = <T>(schema: z.ZodType<T>) => z.object({before: schema, after: schema}).strict()
export type ValueDiff<T> = {before: T, after: T}
export const OptValueDiff = <T>(schema: z.ZodType<T>) => z.object({before: schema.optional(), after: schema.optional()}).strict()
export type OptValueDiff<T> = {before?: T | undefined, after?: T | undefined}

export const ExtraDiff = z.record(z.object({before: z.any(), after: z.any()}))
export type ExtraDiff = z.infer<typeof ExtraDiff>
export const AttributeDiff = z.object({
    name: AttributeName,
    i: ValueDiff(z.number()).optional(),
    type: ValueDiff(AttributeType).optional(),
    null: OptValueDiff(z.boolean()).optional(),
    // gen: z.boolean().optional(), // false when not specified
    default: OptValueDiff(AttributeValue).optional(),
    // attrs: z.lazy(() => Attribute.array().optional()),
    // doc: z.string().optional(),
    // stats: AttributeStats.optional(),
    // extra: AttributeExtra.optional(),
}).strict()
export type AttributeDiff = { // define type explicitly because it's lazy (https://zod.dev/?id=recursive-types)
    name: AttributeName
    i?: ValueDiff<number>,
    type?: ValueDiff<AttributeType>,
    null?: OptValueDiff<boolean>
    // gen?: boolean | undefined
    default?: OptValueDiff<AttributeValue>
    // attrs?: Attribute[] | undefined
    // doc?: string | undefined
    // stats?: AttributeStats | undefined
    // extra?: AttributeExtra | undefined
}
export const EntityDiff = Namespace.extend({
    name: EntityName,
    kind: OptValueDiff(EntityKind),
    def: OptValueDiff(z.string()).optional(),
    attrs: ArrayDiff(Attribute, AttributeDiff).optional(),
    // pk: PrimaryKey.optional(),
    // indexes: Index.array().optional(),
    // checks: Check.array().optional(),
    doc: OptValueDiff(z.string()).optional(),
    // stats: EntityStats.optional(),
    extra: ExtraDiff.optional(),
}).strict()
export type EntityDiff = z.infer<typeof EntityDiff>
export const TypeDiff = Namespace.extend({
    name: TypeName,
    alias: OptValueDiff(z.string()).optional(),
    values: OptValueDiff(z.string().array()).optional(),
    attrs: ArrayDiff(Attribute, AttributeDiff).optional(),
    definition: OptValueDiff(z.string()).optional(),
    doc: OptValueDiff(z.string()).optional(),
    extra: ExtraDiff.optional(),
}).strict().describe('TypeDiff')
export type TypeDiff = z.infer<typeof TypeDiff>
export const DatabaseDiff = z.object({
    entities: ArrayDiff(Entity, EntityDiff).optional(),
    types: ArrayDiff(Type, TypeDiff).optional(),
}).strict().describe('DatabaseDiff')
export type DatabaseDiff = z.infer<typeof DatabaseDiff>


export function databaseDiff(before: Database, after: Database): DatabaseDiff {
    const entities = arrayDiffBy(before.entities || [], after.entities || [], entityToId, entityDiff)
    const types = arrayDiffBy(before.types || [], after.types || [], typeToId, typeDiff)
    return removeEmpty({entities, types})
}

function entityDiff(before: Entity & {i: number}, after: Entity & {i: number}): EntityDiff | undefined {
    const kind = valueDiff(before.kind, after.kind)
    const def = before.def === after.def ? undefined : valueDiff(before.def, after.def)
    const attrs = attributesDiff(before.attrs || [], after.attrs || [])
    const doc = before.doc === after.doc ? undefined : valueDiff(before.doc, after.doc)
    const extra = extraDiff(before.extra || {}, after.extra || {})
    if ([def, attrs, doc, extra].every(v => v === undefined)) return undefined
    return removeUndefined({...typeToNamespace(before), name: before.name, kind, def, attrs, doc, extra})
}

function typeDiff(before: Type & {i: number}, after: Type & {i: number}): TypeDiff | undefined {
    const alias = before.alias === after.alias ? undefined : valueDiff(before.alias, after.alias)
    const values = arraySame(before.values || [], after.values || [], (a, b) => a === b) ? undefined : valueDiff(before.values, after.values)
    const attrs = attributesDiff(before.attrs || [], after.attrs || [])
    const definition = before.definition === after.definition ? undefined : valueDiff(before.definition, after.definition)
    const doc = before.doc === after.doc ? undefined : valueDiff(before.doc, after.doc)
    const extra = extraDiff(before.extra || {}, after.extra || {})
    if ([alias, values, attrs, definition, doc, extra].every(v => v === undefined)) return undefined
    return removeUndefined({...typeToNamespace(before), name: before.name, alias, values, attrs, definition, doc, extra})
}

export function attributesDiff(before: Attribute[], after: Attribute[]): ArrayDiff<Attribute, AttributeDiff> | undefined {
    return arrayDiffBy(before, after, a => a.name, attributeDiff)
}

function attributeDiff(before: Attribute & {i: number}, after: Attribute & {i: number}): AttributeDiff | undefined {
    const i = before.i === after.i ? undefined : valueDiff(before.i, after.i)
    const type = before.type === after.type ? undefined : valueDiff(before.type, after.type)
    const nullable = before.null === after.null ? undefined : valueDiff(before.null, after.null)
    const defaultValue = before.default === after.default ? undefined : valueDiff(before.default, after.default)
    if ([i, type, nullable, defaultValue].every(v => v === undefined)) return undefined
    return removeUndefined({...typeToNamespace(before), name: before.name, i, type, null: nullable, default: defaultValue})
}

function extraDiff(before: Extra, after: Extra): ExtraDiff | undefined {
    const res: ExtraDiff = {}
    Object.entries(before).forEach(([key, value]) => {
        if (!anySame(value, after[key])) {
            res[key] = {before: value, after: after[key]}
        }
    })
    Object.entries(after).forEach(([key, value]) => {
        if (!(key in before)) {
            res[key] = {before: undefined, after: value}
        }
    })
    return Object.keys(res).length === 0 ? undefined : res
}

// generic functions

function arrayDiffBy<T, U>(leftArr: T[], rightArr: T[], getKey: (t: T) => string, makeDiff: (a: T & {i: number}, b: T & {i: number}) => U | undefined): ArrayDiff<T, U> | undefined {
    const {left: deleted, right: created, both: common} = diffBy(leftArr.map((v, i) => Object.assign({i}, v)), rightArr.map((v, i) => Object.assign({i}, v)), getKey)
    const updated: U[] = []
    const unchanged: (T & {i: number})[] = []
    common.forEach(({left, right}) => {
        const res = makeDiff(left, right)
        res === undefined ? unchanged.push(left) : updated.push(res)
    })
    return unchanged.length > 0 || updated.length > 0 || created.length > 0 || deleted.length > 0 ? removeEmpty({unchanged, updated, created, deleted}) : undefined
}

function valueDiff<T>(before: T, after: T): ValueDiff<T> {
    return {before, after}
}
