import {z} from "zod";
import {anySame, arraySame, diffBy, equalDeep, objectSame, removeEmpty, removeUndefined} from "@azimutt/utils";
import {
    Attribute,
    AttributeName,
    AttributePath,
    AttributeType,
    AttributeValue,
    Check,
    ConstraintName,
    Database,
    Entity,
    EntityKind,
    EntityName,
    EntityRef,
    Extra,
    Index,
    Namespace,
    PrimaryKey,
    Relation,
    Type,
    TypeName
} from "./database";
import {
    attributePathToId,
    entityToId,
    relationLinkToAttributeRef,
    relationToId,
    typeToId,
    typeToNamespace
} from "./databaseUtils";

// FIXME: Work In Progress
// cf https://github.com/andreyvit/json-diff

export const ArrayDiff = <T, U>(schema: z.ZodType<T>, schemaDiff: z.ZodType<U>): z.ZodType<ArrayDiff<T, U>> => z.object({
    unchanged: schema.and(z.object({i: z.number()})).array(), // both present but same
    updated: schemaDiff.array(), // both present but different
    created: schema.and(z.object({i: z.number()})).array(), // after only
    deleted: schema.and(z.object({i: z.number()})).array(), // before only
}).strict().describe('ArrayDiff')
export type ArrayDiff<T, U> = {unchanged: (T & {i: number})[], updated: U[], created: (T & {i: number})[], deleted: (T & {i: number})[]}

export const ValueDiff = <T>(schema: z.ZodType<T>) => z.object({before: schema, after: schema}).strict()
export type ValueDiff<T> = {before: T, after: T}
export const OptValueDiff = <T>(schema: z.ZodType<T>) => z.object({before: schema.optional(), after: schema.optional()}).strict()
export type OptValueDiff<T> = {before?: T | undefined, after?: T | undefined}

export const ExtraDiff = z.record(z.object({before: z.any(), after: z.any()})).describe('ExtraDiff')
export type ExtraDiff = z.infer<typeof ExtraDiff>
export const AttributeDiff = z.object({
    name: AttributeName,
    i: ValueDiff(z.number()).optional(),
    type: ValueDiff(AttributeType).optional(),
    null: OptValueDiff(z.boolean()).optional(),
    // gen: z.boolean().optional(), // false when not specified
    default: OptValueDiff(AttributeValue).optional(),
    // attrs: z.lazy(() => Attribute.array().optional()),
    doc: OptValueDiff(z.string()).optional(),
    // stats: AttributeStats.optional(),
    extra: ExtraDiff.optional(),
}).strict().describe('AttributeDiff')
export type AttributeDiff = { // define type explicitly because it's lazy (https://zod.dev/?id=recursive-types)
    name: AttributeName
    i?: ValueDiff<number>
    type?: ValueDiff<AttributeType>
    null?: OptValueDiff<boolean>
    // gen?: boolean | undefined
    default?: OptValueDiff<AttributeValue>
    // attrs?: Attribute[] | undefined
    doc?: OptValueDiff<string>
    // stats?: AttributeStats | undefined
    extra?: ExtraDiff
}
export const IndexDiff = z.object({
    attrs: AttributePath.array(),
    name: ConstraintName.optional(), // keep the name even if it didn't change
    i: ValueDiff(z.number()).optional(),
    rename: OptValueDiff(ConstraintName).optional(),
    unique: OptValueDiff(z.boolean()).optional(),
    partial: OptValueDiff(z.string()).optional(),
    definition: OptValueDiff(z.string()).optional(),
    doc: OptValueDiff(z.string()).optional(),
    // stats: IndexStats.optional(),
    extra: ExtraDiff.optional(),
}).strict().describe('IndexDiff')
export type IndexDiff = z.infer<typeof IndexDiff>
export const CheckDiff = z.object({
    attrs: AttributePath.array(),
    name: ConstraintName.optional(), // keep the name even if it didn't change
    i: ValueDiff(z.number()).optional(),
    rename: OptValueDiff(ConstraintName).optional(),
    predicate: OptValueDiff(z.string()).optional(),
    doc: OptValueDiff(z.string()).optional(),
    // stats: IndexStats.optional(),
    extra: ExtraDiff.optional(),
}).strict().describe('CheckDiff')
export type CheckDiff = z.infer<typeof CheckDiff>
export const EntityDiff = Namespace.extend({
    name: EntityName,
    rename: OptValueDiff(EntityName).optional(),
    kind: OptValueDiff(EntityKind).optional(),
    def: OptValueDiff(z.string()).optional(),
    attrs: ArrayDiff(Attribute, AttributeDiff).optional(),
    pk: OptValueDiff(PrimaryKey).optional(),
    indexes: ArrayDiff(Index, IndexDiff).optional(),
    checks: ArrayDiff(Check, CheckDiff).optional(),
    doc: OptValueDiff(z.string()).optional(),
    // stats: EntityStats.optional(),
    extra: ExtraDiff.optional(),
}).strict().describe('EntityDiff')
export type EntityDiff = z.infer<typeof EntityDiff>
export const RelationDiff = z.object({
    src: EntityRef.extend({attrs: AttributePath.array()}),
    ref: EntityRef.extend({attrs: AttributePath.array()}),
    name: ConstraintName.optional(),
    rename: OptValueDiff(z.string()).optional(),
}).strict().describe('RelationDiff')
export type RelationDiff = z.infer<typeof RelationDiff>
export const TypeDiff = Namespace.extend({
    name: TypeName,
    rename: OptValueDiff(TypeName).optional(),
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
    relations: ArrayDiff(Relation, RelationDiff).optional(),
    types: ArrayDiff(Type, TypeDiff).optional(),
}).strict().describe('DatabaseDiff')
export type DatabaseDiff = z.infer<typeof DatabaseDiff>


export function databaseDiff(before: Database, after: Database): DatabaseDiff {
    const entities = guessRenames(arrayDiffBy(before.entities || [], after.entities || [], entityToId, entityDiff), entityDiff)
    const relations = arrayDiffBy(before.relations || [], after.relations || [], relationToId, relationDiff)
    const types = guessRenames(arrayDiffBy(before.types || [], after.types || [], typeToId, typeDiff), typeDiff)
    return removeEmpty({entities, relations, types})
}

function entityDiff(before: Entity & {i: number}, after: Entity & {i: number}): EntityDiff | undefined {
    const rename = before.name === after.name ? undefined : valueDiff(before.name, after.name)
    const kind = before.kind === undefined && after.kind === undefined ? undefined : valueDiff(before.kind, after.kind)
    const def = before.def === after.def ? undefined : valueDiff(before.def, after.def)
    const attrs = attributesDiff(before.attrs || [], after.attrs || [])
    const pk = equalDeep(before.pk, after.pk) ? undefined : valueDiff(before.pk, after.pk)
    const indexes = indexesDiff(before.indexes || [], after.indexes || [])
    const checks = checksDiff(before.checks || [], after.checks || [])
    const doc = before.doc === after.doc ? undefined : valueDiff(before.doc, after.doc)
    const extra = extraDiff(before.extra || {}, after.extra || {})
    if ([rename, kind, def, attrs, pk, indexes, checks, doc, extra].every(v => v === undefined)) return undefined
    return removeUndefined({...typeToNamespace(after), name: after.name, rename, kind, def, attrs, pk, indexes, checks, doc, extra})
}

function relationDiff(before: Relation & {i: number}, after: Relation & {i: number}): RelationDiff | undefined {
    const rename = before.name === after.name ? undefined : valueDiff(before.name, after.name)
    const doc = before.doc === after.doc ? undefined : valueDiff(before.doc, after.doc)
    const extra = extraDiff(before.extra || {}, after.extra || {})
    if ([rename, doc, extra].every(v => v === undefined)) return undefined
    return removeUndefined({src: relationLinkToAttributeRef(after.src), ref: relationLinkToAttributeRef(after.ref), name: after.name, rename, doc, extra})
}

function typeDiff(before: Type & {i: number}, after: Type & {i: number}): TypeDiff | undefined {
    const rename = before.name === after.name ? undefined : valueDiff(before.name, after.name)
    const alias = before.alias === after.alias ? undefined : valueDiff(before.alias, after.alias)
    const values = arraySame(before.values || [], after.values || [], (a, b) => a === b) ? undefined : valueDiff(before.values, after.values)
    const attrs = attributesDiff(before.attrs || [], after.attrs || [])
    const definition = before.definition === after.definition ? undefined : valueDiff(before.definition, after.definition)
    const doc = before.doc === after.doc ? undefined : valueDiff(before.doc, after.doc)
    const extra = extraDiff(before.extra || {}, after.extra || {})
    if ([rename, alias, values, attrs, definition, doc, extra].every(v => v === undefined)) return undefined
    return removeUndefined({...typeToNamespace(after), name: after.name, rename, alias, values, attrs, definition, doc, extra})
}

export function attributesDiff(before: Attribute[], after: Attribute[]): ArrayDiff<Attribute, AttributeDiff> | undefined {
    return arrayDiffBy(before, after, a => a.name, attributeDiff)
}

function attributeDiff(before: Attribute & {i: number}, after: Attribute & {i: number}): AttributeDiff | undefined {
    const i = before.i === after.i ? undefined : valueDiff(before.i, after.i)
    const type = before.type === after.type ? undefined : valueDiff(before.type, after.type)
    const nullable = before.null === after.null ? undefined : valueDiff(before.null, after.null)
    const defaultValue = before.default === after.default ? undefined : valueDiff(before.default, after.default)
    const doc = before.doc === after.doc ? undefined : valueDiff(before.doc, after.doc)
    const extra = extraDiff(before.extra || {}, after.extra || {})
    if ([i, type, nullable, defaultValue, doc, extra].every(v => v === undefined)) return undefined
    return removeUndefined({...typeToNamespace(before), name: before.name, i, type, null: nullable, default: defaultValue, doc, extra})
}

export function indexesDiff(before: Index[], after: Index[]): ArrayDiff<Index, IndexDiff> | undefined {
    return guessRenames(arrayDiffBy(before, after, i => i.name || i.attrs.map(attributePathToId).join(','), indexDiff), indexDiff)
}

function indexDiff(before: Index & {i: number}, after: Index & {i: number}): IndexDiff | undefined {
    const i = before.i === after.i ? undefined : valueDiff(before.i, after.i)
    const rename = before.name === after.name ? undefined : valueDiff(before.name, after.name)
    const unique = before.unique === after.unique ? undefined : valueDiff(before.unique, after.unique)
    const partial = before.partial === after.partial ? undefined : valueDiff(before.partial, after.partial)
    const definition = before.definition === after.definition ? undefined : valueDiff(before.definition, after.definition)
    const doc = before.doc === after.doc ? undefined : valueDiff(before.doc, after.doc)
    const extra = extraDiff(before.extra || {}, after.extra || {})
    if ([i, rename, unique, partial, definition, doc, extra].every(v => v === undefined)) return undefined
    return removeUndefined({attrs: after.attrs, name: after.name, i, rename, unique, partial, definition, doc, extra})
}

export function checksDiff(before: Check[], after: Check[]): ArrayDiff<Check, CheckDiff> | undefined {
    return guessRenames(arrayDiffBy(before, after, c => c.name || c.attrs.map(attributePathToId).join(','), checkDiff), checkDiff)
}

function checkDiff(before: Check & {i: number}, after: Check & {i: number}): CheckDiff | undefined {
    const i = before.i === after.i ? undefined : valueDiff(before.i, after.i)
    const rename = before.name === after.name ? undefined : valueDiff(before.name, after.name)
    const predicate = before.predicate === after.predicate ? undefined : valueDiff(before.predicate, after.predicate)
    const doc = before.doc === after.doc ? undefined : valueDiff(before.doc, after.doc)
    const extra = extraDiff(before.extra || {}, after.extra || {})
    if ([i, rename, predicate, doc, extra].every(v => v === undefined)) return undefined
    return removeUndefined({attrs: after.attrs, name: after.name, i, rename, predicate, doc, extra})
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

function guessRenames<T extends {name?: string}, D>(arr: ArrayDiff<T, D> | undefined, makeDiff: (before: T & {i: number}, after: T & {i: number}) => D | undefined): ArrayDiff<T, D> | undefined {
    const {unchanged, updated, created, deleted} = arr || {}
    const newUnchanged = unchanged || [], newUpdated = updated || [], newDeleted = deleted || []
    const newCreated = (created || []).filter(afterValue => {
        const {name, ...after} = afterValue
        const sameDeleted = newDeleted.findIndex(({name, ...d}) => objectSame(after, d))
        if (sameDeleted !== -1) {
            const diff = makeDiff(newDeleted[sameDeleted], afterValue)
            diff && newUpdated.push(diff)
            newDeleted.splice(sameDeleted, 1)
            return false
        } else {
            return true
        }
    })
    return newUnchanged.length > 0 || newUpdated.length > 0 || newCreated.length > 0 || newDeleted.length > 0 ? removeEmpty({unchanged: newUnchanged, updated: newUpdated, created: newCreated, deleted: newDeleted}) : undefined
}
