import {z} from "zod";
import {removeEmpty, removeUndefined} from "@azimutt/utils";
import {
    Attribute,
    AttributePath,
    AttributeRef,
    AttributeValue,
    Check,
    Database,
    Entity,
    EntityRef,
    Index,
    PrimaryKey,
    Relation,
    Type
} from "../database";
import {ValueSchema} from "../inferSchema";

export const legacyColumnPathSeparator = ":"
export const legacyColumnTypeUnknown: LegacyColumnType = 'unknown'

const LegacyJsValueLiteral = z.union([z.string(), z.number(), z.boolean(), z.null()])
type LegacyJsValueLiteral = z.infer<typeof LegacyJsValueLiteral>
export const LegacyJsValue: z.ZodType<LegacyJsValue> = z.lazy(() => z.union([LegacyJsValueLiteral, z.array(LegacyJsValue), z.record(LegacyJsValue)]))
export type LegacyJsValue = LegacyJsValueLiteral | { [key: string]: LegacyJsValue } | LegacyJsValue[] // lazy so can't infer type :/

export type LegacySchemaName = string
export const LegacySchemaName = z.string()
export type LegacyTableName = string
export const LegacyTableName = z.string()
export type LegacyTableId = string // ex: 'public.users'
export const LegacyTableId = z.string()
export type LegacyColumnName = string
export const LegacyColumnName = z.string()
export type LegacyColumnType = string
export const LegacyColumnType = z.string()
export type LegacyColumnValue = string
export const LegacyColumnValue = z.string()
export type LegacyColumnId = string // ex: 'public.users.id'
export const LegacyColumnId = z.string()
export type LegacyPrimaryKey = { name?: string | null, columns: LegacyColumnName[] }
export const LegacyPrimaryKey = z.object({name: z.string().nullish(), columns: LegacyColumnName.array()}).strict()
export type LegacyUnique = { name?: string | null, columns: LegacyColumnName[], definition?: string | null }
export const LegacyUnique = z.object({
    name: z.string().nullish(),
    columns: LegacyColumnName.array(),
    definition: z.string().nullish()
}).strict()
export type LegacyIndex = { name?: string | null, columns: LegacyColumnName[], definition?: string | null }
export const LegacyIndex = z.object({
    name: z.string().nullish(),
    columns: LegacyColumnName.array(),
    definition: z.string().nullish()
}).strict()
export type LegacyCheck = { name?: string | null, columns: LegacyColumnName[], predicate?: string | null }
export const LegacyCheck = z.object({
    name: z.string().nullish(),
    columns: LegacyColumnName.array(),
    predicate: z.string().nullish()
}).strict()
export type LegacyColumn = {
    name: LegacyColumnName
    type: LegacyColumnType
    nullable?: boolean | null
    default?: LegacyColumnValue | null
    comment?: string | null
    values?: string[] | null
    columns?: LegacyColumn[] | null
}
export const LegacyColumn: z.ZodType<LegacyColumn> = z.object({
    name: LegacyColumnName,
    type: LegacyColumnType,
    nullable: z.boolean().nullish(),
    default: LegacyColumnValue.nullish(),
    comment: z.string().nullish(),
    values: z.string().array().nullish(),
    columns: z.lazy(() => LegacyColumn.array().nullish())
}).strict()
// TODO: mutualise with Table in libs/models/src/legacy/legacyProject.ts:237
export type LegacyTable = {
    schema: LegacySchemaName
    table: LegacyTableName
    columns: LegacyColumn[]
    view?: boolean | null
    primaryKey?: LegacyPrimaryKey | null
    uniques?: LegacyUnique[] | null
    indexes?: LegacyIndex[] | null
    checks?: LegacyCheck[] | null
    comment?: string | null
}
export const LegacyTable = z.object({
    schema: LegacySchemaName,
    table: LegacyTableName,
    columns: LegacyColumn.array(),
    view: z.boolean().nullish(),
    primaryKey: LegacyPrimaryKey.nullish(),
    uniques: LegacyUnique.array().nullish(),
    indexes: LegacyIndex.array().nullish(),
    checks: LegacyCheck.array().nullish(),
    comment: z.string().nullish()
}).strict()
export type LegacyRelationName = string
export const LegacyRelationName = z.string()
export type LegacyColumnRef = { schema: LegacySchemaName, table: LegacyTableName, column: LegacyColumnName }
export const LegacyColumnRef = z.object({
    schema: LegacySchemaName,
    table: LegacyTableName,
    column: LegacyColumnName
}).strict()
export type LegacyRelation = { name: LegacyRelationName, src: LegacyColumnRef, ref: LegacyColumnRef }
export const LegacyRelation = z.object({name: LegacyRelationName, src: LegacyColumnRef, ref: LegacyColumnRef}).strict()
type LegacyTypeContent = { values: string[] | null } | { definition: string }
const LegacyTypeContent = z.union([
    z.object({values: z.string().array().nullable()}),
    z.object({definition: z.string()})
])
export type LegacyTypeName = string
export const LegacyTypeName = z.string()
export type LegacyType = { schema: LegacySchemaName, name: LegacyTypeName } & LegacyTypeContent
export const LegacyType = z.object({
    schema: LegacySchemaName,
    name: LegacyTypeName
}).and(LegacyTypeContent)
export type LegacyDatabase = { tables: LegacyTable[], relations: LegacyRelation[], types?: LegacyType[] | null }
export const LegacyDatabase = z.object({
    tables: LegacyTable.array(),
    relations: LegacyRelation.array(),
    types: LegacyType.array().nullish()
}).strict().describe('LegacyDatabase')

export function schemaToColumns(schema: ValueSchema, flatten: number, path: string[] = []): LegacyColumn[] {
    // TODO: if string with few values (< 10% of docs), handle it like an enum and add values in comment
    if (schema.nested && flatten > 0) {
        return Object.entries(schema.nested).flatMap(([key, value]) => {
            return [{
                name: path.map(p => p + '.').join('') + key,
                type: value.type,
                nullable: value.nullable
            }, ...schemaToColumns(value, flatten - 1, [...path, key])]
        })
    } else if (schema.nested) {
        return Object.entries(schema.nested).map(([key, value]) => {
            return removeUndefined({
                name: path.map(p => p + '.').join('') + key,
                type: value.type,
                nullable: value.nullable,
                columns: value.nested ? schemaToColumns(value, 0, []) : undefined
            })
        })
    } else {
        return []
    }
}

export function databaseFromLegacy(db: LegacyDatabase): Database {
    return removeEmpty({
        entities: db.tables.map(tableFromLegacy),
        relations: db.relations.map(relationFromLegacy),
        types: db.types?.map(typeFromLegacy)
    })
}

export function databaseToLegacy(db: Database): LegacyDatabase {
    return removeUndefined({
        tables: db.entities?.map(tableToLegacy) || [],
        relations: db.relations?.map(relationToLegacy) || [],
        types: db.types?.map(typeToLegacy)
    })
}

function tableFromLegacy(t: LegacyTable): Entity {
    return removeEmpty({
        schema: t.schema,
        name: t.table,
        kind: t.view ? 'view' as const : undefined,
        attrs: t.columns.map(columnFromLegacy),
        pk: t.primaryKey ? primaryKeyFromLegacy(t.primaryKey) : undefined,
        indexes: (t.uniques ||  []).map(uniqueFromLegacy).concat((t.indexes || []).map(indexFromLegacy)),
        checks: t.checks?.map(checkFromLegacy),
        doc: t.comment || undefined
    })
}

function tableToLegacy(e: Entity): LegacyTable {
    const uniques = e.indexes?.filter(i => i.unique) || []
    const indexes = e.indexes?.filter(i => !i.unique) || []
    return removeUndefined({
        schema: e.schema || '',
        table: e.name,
        columns: e.attrs.map(columnToLegacy),
        view: e.kind === 'view' || e.kind === 'materialized view' || undefined,
        primaryKey: e.pk ? primaryKeyToLegacy(e.pk) : undefined,
        uniques: uniques.length > 0 ? uniques.map(uniqueToLegacy) : undefined,
        indexes: indexes.length > 0 ? indexes.map(indexToLegacy) : undefined,
        checks: e.checks ? e.checks.map(checkToLegacy) : undefined,
        comment: e.doc
    })
}

function columnFromLegacy(c: LegacyColumn): Attribute {
    return removeUndefined({
        name: c.name,
        type: c.type,
        nullable: c.nullable || undefined,
        default: c.default ? columnValueFromLegacy(c.default) : undefined,
        values: c.values?.map(columnValueFromLegacy) || undefined,
        attrs: c.columns?.map(columnFromLegacy),
        doc: c.comment || undefined,
    })
}

function columnToLegacy(a: Attribute): LegacyColumn {
    return removeUndefined({
        name: a.name,
        type: a.type,
        nullable: a.nullable,
        default: a.default ? columnValueToLegacy(a.default) : undefined,
        comment: a.doc,
        values: a.values?.map(columnValueToLegacy),
        columns: a.attrs?.map(columnToLegacy)
    })
}

export function columnValueFromLegacy(v: LegacyColumnValue): AttributeValue {
    return v
}

export function columnValueToLegacy(v: AttributeValue): LegacyColumnValue {
    if (v === undefined) return 'null'
    if (v === null) return 'null'
    return v.toString() // TODO: improve?
}

function primaryKeyFromLegacy(pk: LegacyPrimaryKey): PrimaryKey {
    return removeUndefined({
        name: pk.name || undefined,
        attrs: pk.columns.map(columnNameFromLegacy)
    })
}
function primaryKeyToLegacy(pk: PrimaryKey): LegacyPrimaryKey {
    return removeUndefined({
        name: pk.name,
        columns: pk.attrs.map(columnNameToLegacy)
    })
}

function columnNameFromLegacy(n: LegacyColumnName): AttributePath {
    return n.split(legacyColumnPathSeparator)
}

function columnNameToLegacy(p: AttributePath): LegacyColumnName {
    return p.join(legacyColumnPathSeparator)
}

function uniqueFromLegacy(u: LegacyUnique): Index {
    return removeUndefined({
        name: u.name || undefined,
        attrs: u.columns.map(columnNameFromLegacy),
        unique: true,
        definition: u.definition || undefined,
    })
}

function uniqueToLegacy(i: Index): LegacyUnique {
    return removeUndefined({
        name: i.name,
        columns: i.attrs.map(columnNameToLegacy),
        definition: i.definition
    })
}

function indexFromLegacy(i: LegacyIndex): Index {
    return removeUndefined({
        name: i.name || undefined,
        attrs: i.columns.map(columnNameFromLegacy),
        definition: i.definition || undefined,
    })
}

function indexToLegacy(i: Index): LegacyIndex {
    return removeUndefined({
        name: i.name,
        columns: i.attrs.map(columnNameToLegacy),
        definition: i.definition
    })
}

function checkFromLegacy(c: LegacyCheck): Check {
    return removeUndefined({
        name: c.name || undefined,
        attrs: c.columns.map(columnNameFromLegacy),
        predicate: c.predicate || '',
    })
}

function checkToLegacy(c: Check): LegacyCheck {
    return removeUndefined({
        name: c.name,
        columns: c.attrs.map(columnNameToLegacy),
        predicate: c.predicate || undefined
    })
}

function relationFromLegacy(r: LegacyRelation): Relation {
    return removeUndefined({
        name: r.name || undefined,
        src: columnRefFromLegacy2(r.src),
        ref: columnRefFromLegacy2(r.ref),
        attrs: [{src: r.src.column.split(legacyColumnPathSeparator), ref: r.ref.column.split(legacyColumnPathSeparator)}],
    })
}

function relationToLegacy(r: Relation): LegacyRelation {
    const attr = r.attrs[0]
    return { name: r.name || '', src: columnRefToLegacy2(r.src, attr.src), ref: columnRefToLegacy2(r.ref, attr.ref) }
}

export function columnRefFromLegacy(c: LegacyColumnRef): AttributeRef {
    return removeUndefined({schema: c.schema || undefined, entity: c.table, attribute: [c.column]}) // FIXME: use function from ColumnName to AttributePath
}

export function columnRefToLegacy(a: AttributeRef): LegacyColumnRef {
    return {schema: a.schema || '', table: a.entity, column: a.attribute.join(legacyColumnPathSeparator)} // FIXME: use function from AttributePath to ColumnName
}

function columnRefFromLegacy2(e: LegacyColumnRef): EntityRef {
    return removeUndefined({schema: e.schema || undefined, entity: e.table})
}

function columnRefToLegacy2(e: EntityRef, c: AttributePath): LegacyColumnRef {
    return {schema: e.schema || '', table: e.entity, column: c.join(legacyColumnPathSeparator)}
}

function typeFromLegacy(t: LegacyType): Type {
    if ('values' in t) {
        return {schema: t.schema, name: t.name, values: t.values || undefined}
    } else {
        return {schema: t.schema, name: t.name, definition: t.definition}
    }
}

function typeToLegacy(t: Type): LegacyType {
    if (t.values) {
        return {schema: t.schema || '', name: t.name, values: t.values}
    } else {
        return {schema: t.schema || '', name: t.name, definition: t.definition || ''}
    }
}
