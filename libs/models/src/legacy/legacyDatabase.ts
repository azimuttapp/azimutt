import {z} from "zod";
import {groupBy, indexBy, mapValues, removeEmpty, removeUndefined} from "@azimutt/utils";
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
import {entityToId, entityRefToId, typeToId} from "../databaseUtils";
import {DateTime} from "../common";

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
export const LegacyColumnDbStats = z.object({
    nulls: z.number().optional(), // percentage of nulls
    bytesAvg: z.number().optional(), // average bytes for a value
    cardinality: z.number().optional(), // number of different values
    commonValues: z.object({
        value: LegacyColumnValue,
        freq: z.number()
    }).strict().array().optional(),
    histogram: LegacyColumnValue.array().optional()
}).strict()
export type LegacyColumnDbStats = z.infer<typeof LegacyColumnDbStats>
export type LegacyColumn = {
    name: LegacyColumnName
    type: LegacyColumnType
    nullable?: boolean | null
    default?: LegacyColumnValue | null
    comment?: string | null
    values?: string[] | null
    columns?: LegacyColumn[] | null
    stats?: LegacyColumnDbStats | null
}
export const LegacyColumn: z.ZodType<LegacyColumn> = z.object({
    name: LegacyColumnName,
    type: LegacyColumnType,
    nullable: z.boolean().nullish(),
    default: LegacyColumnValue.nullish(),
    comment: z.string().nullish(),
    values: z.string().array().nullish(),
    columns: z.lazy(() => LegacyColumn.array().nullish()),
    stats: LegacyColumnDbStats.nullish()
}).strict()
export const LegacyTableDbStats = z.object({
    rows: z.number().optional(), // number of rows
    size: z.number().optional(), // used bytes
    sizeIdx: z.number().optional(), // used bytes for indexes
    scanSeq: z.number().optional(), // number of seq scan
    scanSeqLast: DateTime.optional(),
    scanIdx: z.number().optional(), // number of index scan
    scanIdxLast: DateTime.optional(),
    analyzeLast: DateTime.optional(),
    vacuumLast: DateTime.optional(),
}).strict()
export type LegacyTableDbStats = z.infer<typeof LegacyTableDbStats>
export type LegacyTable = {
    schema: LegacySchemaName
    table: LegacyTableName
    columns: LegacyColumn[]
    view?: boolean | null
    definition?: string | null
    primaryKey?: LegacyPrimaryKey | null
    uniques?: LegacyUnique[] | null
    indexes?: LegacyIndex[] | null
    checks?: LegacyCheck[] | null
    comment?: string | null
    stats?: LegacyTableDbStats | null
}
export const LegacyTable = z.object({
    schema: LegacySchemaName,
    table: LegacyTableName,
    columns: LegacyColumn.array(),
    view: z.boolean().nullish(),
    definition: z.string().nullish(), // query definition for views
    primaryKey: LegacyPrimaryKey.nullish(),
    uniques: LegacyUnique.array().nullish(),
    indexes: LegacyIndex.array().nullish(),
    checks: LegacyCheck.array().nullish(),
    comment: z.string().nullish(),
    stats: LegacyTableDbStats.nullish(),
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
        entities: indexBy(db.tables.map(tableFromLegacy), entityToId),
        relations: mapValues(groupBy(db.relations.map(relationFromLegacy), r => entityRefToId(r.src)), rels => groupBy(rels, r => entityRefToId(r.ref))),
        types: indexBy(db.types?.map(typeFromLegacy) || [], typeToId)
    })
}

export function databaseToLegacy(db: Database): LegacyDatabase {
    return removeUndefined({
        tables: Object.values(db.entities || {}).map(tableToLegacy),
        relations: Object.values(db.relations || {}).flatMap(Object.values).map(relationToLegacy),
        types: Object.values(db.types || {}).map(typeToLegacy)
    })
}

function tableFromLegacy(t: LegacyTable): Entity {
    return removeEmpty({
        schema: t.schema,
        name: t.table,
        kind: t.view ? 'view' as const : undefined,
        def: t.definition || undefined,
        attrs: indexBy(t.columns.map(columnFromLegacy), c => c.name),
        pk: t.primaryKey ? primaryKeyFromLegacy(t.primaryKey) : undefined,
        indexes: (t.uniques ||  []).map(uniqueFromLegacy).concat((t.indexes || []).map(indexFromLegacy)),
        checks: t.checks?.map(checkFromLegacy),
        doc: t.comment || undefined,
        stats: t.stats ? removeUndefined({
            rows: t.stats.rows,
            size: t.stats.size,
            sizeIdx: t.stats.sizeIdx,
            scanSeq: t.stats.scanSeq,
            scanSeqLast: t.stats.scanSeqLast,
            scanIdx: t.stats.scanIdx,
            scanIdxLast: t.stats.scanIdxLast,
            analyzeLast: t.stats.analyzeLast,
            vacuumLast: t.stats.vacuumLast,
        }) : undefined,
    })
}

function tableToLegacy(e: Entity): LegacyTable {
    const uniques = e.indexes?.filter(i => i.unique) || []
    const indexes = e.indexes?.filter(i => !i.unique) || []
    return removeUndefined({
        schema: e.schema || '',
        table: e.name,
        columns: Object.values(e.attrs).sort((a, b) => a.pos - b.pos).map(columnToLegacy),
        view: e.kind === 'view' || e.kind === 'materialized view' || undefined,
        definition: e.def,
        primaryKey: e.pk ? primaryKeyToLegacy(e.pk) : undefined,
        uniques: uniques.length > 0 ? uniques.map(uniqueToLegacy) : undefined,
        indexes: indexes.length > 0 ? indexes.map(indexToLegacy) : undefined,
        checks: e.checks ? e.checks.map(checkToLegacy) : undefined,
        comment: e.doc,
        stats: e.stats ? removeUndefined({
            rows: e.stats.rows,
            size: e.stats.size,
            sizeIdx: e.stats.sizeIdx,
            scanSeq: e.stats.scanSeq,
            scanSeqLast: e.stats.scanSeqLast,
            scanIdx: e.stats.scanIdx,
            scanIdxLast: e.stats.scanIdxLast,
            analyzeLast: e.stats.analyzeLast,
            vacuumLast: e.stats.vacuumLast,
        }) : undefined,
    })
}

function columnFromLegacy(c: LegacyColumn, index: number): Attribute {
    return removeUndefined({
        pos: index + 1,
        name: c.name,
        type: c.type,
        null: c.nullable || undefined,
        default: c.default ? columnValueFromLegacy(c.default) : undefined,
        attrs: c.columns ? indexBy(c.columns.map(columnFromLegacy), cc => cc.name) : undefined,
        doc: c.comment || undefined,
        stats: c.stats ? removeUndefined({
            nulls: c.stats.nulls,
            avgBytes: c.stats.bytesAvg,
            cardinality: c.stats.cardinality,
            commonValues: c.stats.commonValues?.map(v => ({value: columnValueFromLegacy(v.value), freq: v.freq})),
            distinctValues: c.values?.map(columnValueFromLegacy) || undefined,
            histogram: c.stats.histogram?.map(columnValueFromLegacy),
        }) : undefined,
    })
}

function columnToLegacy(a: Attribute): LegacyColumn {
    return removeEmpty({
        name: a.name,
        type: a.type,
        nullable: a.null,
        default: a.default ? columnValueToLegacy(a.default) : undefined,
        comment: a.doc,
        values: a.stats?.distinctValues?.map(columnValueToLegacy),
        columns: a.attrs ? Object.values(a.attrs).sort((a, b) => a.pos - b.pos).map(columnToLegacy) : undefined,
        stats: a.stats ? removeUndefined({
            nulls: a.stats.nulls,
            bytesAvg: a.stats.bytesAvg,
            cardinality: a.stats.cardinality,
            commonValues: a.stats.commonValues?.map(v => ({value: columnValueToLegacy(v.value), freq: v.freq})),
            histogram: a.stats.histogram?.map(columnValueToLegacy),
        }) : undefined,
    })
}

export function columnValueFromLegacy(v: LegacyColumnValue): AttributeValue {
    return v
}

export function columnValueToLegacy(v: AttributeValue): LegacyColumnValue {
    if (v === undefined) return 'null'
    if (v === null) return 'null'
    if (typeof v === 'object') return JSON.stringify(v)
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
    // FIXME: use function from ColumnName to AttributePath
    return removeUndefined({schema: c.schema || undefined, entity: c.table, attribute: [c.column]})
}

export function columnRefToLegacy(a: AttributeRef): LegacyColumnRef {
    // FIXME: use function from AttributePath to ColumnName
    return {schema: a.schema || '', table: a.entity, column: a.attribute.join(legacyColumnPathSeparator)}
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
