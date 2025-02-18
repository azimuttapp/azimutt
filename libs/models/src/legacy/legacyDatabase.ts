import {z} from "zod";
import {errorToString, removeEmpty, removeUndefined, stringify, zip} from "@azimutt/utils";
import {
    Attribute,
    AttributePath,
    AttributeRef,
    AttributeStats,
    AttributeValue,
    Check,
    Database,
    Entity,
    EntityRef,
    EntityStats,
    Index,
    PrimaryKey,
    Relation,
    Type
} from "../database";
import {attributePathToId, attributeValueToString, entityToId} from "../databaseUtils";
import {ValueSchema} from "../inferSchema";
import {DateTime} from "../common";

export const legacyColumnPathSeparator = ":"
export const legacyColumnTypeUnknown: LegacyColumnType = 'unknown'

const LegacyJsValueLiteral = z.union([z.string(), z.number(), z.boolean(), z.date(), z.null()])
type LegacyJsValueLiteral = z.infer<typeof LegacyJsValueLiteral>
export const LegacyJsValue: z.ZodType<LegacyJsValue> = z.lazy(() => z.union([LegacyJsValueLiteral, z.array(LegacyJsValue), z.record(LegacyJsValue)]))
export type LegacyJsValue = LegacyJsValueLiteral | { [key: string]: LegacyJsValue } | LegacyJsValue[] // lazy so can't infer type :/

export type LegacySchemaName = string
export const LegacySchemaName = z.string()
export type LegacyTableName = string
export const LegacyTableName = z.string()
export type LegacyTableId = string // ex: 'public.users' or '.users' if no schema
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
    histogram: LegacyColumnValue.array().optional(),
}).strict()
export type LegacyColumnDbStats = z.infer<typeof LegacyColumnDbStats>
export type LegacyColumn = {
    name: LegacyColumnName
    type: LegacyColumnType
    nullable?: boolean | null | undefined
    default?: LegacyColumnValue | null | undefined
    comment?: string | null | undefined
    values?: string[] | null | undefined
    columns?: LegacyColumn[] | null | undefined
    stats?: LegacyColumnDbStats | null | undefined
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
export type LegacyTableRef = { schema: LegacySchemaName, table: LegacyTableName }
export const LegacyTableRef = z.object({
    schema: LegacySchemaName,
    table: LegacyTableName,
}).strict()
export type LegacyColumnRef = { table: LegacyTableId, column: LegacyColumnName }
export const LegacyColumnRef = z.object({
    table: LegacyTableId,
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
        relations: db.relations?.flatMap(relationToLegacy) || [],
        types: db.types?.map(typeToLegacy)
    })
}

function tableFromLegacy(t: LegacyTable): Entity {
    return removeEmpty({
        database: undefined,
        catalog: undefined,
        schema: t.schema || undefined,
        name: t.table,
        kind: t.view ? 'view' as const : undefined,
        def: t.definition || undefined,
        attrs: t.columns.map(columnFromLegacy),
        pk: t.primaryKey ? primaryKeyFromLegacy(t.primaryKey) : undefined,
        indexes: (t.uniques ||  []).map(uniqueFromLegacy).concat((t.indexes || []).map(indexFromLegacy)),
        checks: t.checks?.map(checkFromLegacy),
        doc: t.comment || undefined,
        stats: t.stats ? tableDbStatsFromLegacy(t.stats) : undefined,
    })
}

function tableToLegacy(e: Entity): LegacyTable {
    const uniques = e.indexes?.filter(i => i.unique) || []
    const indexes = e.indexes?.filter(i => !i.unique) || []
    return removeUndefined({
        schema: e.schema || '',
        table: e.name,
        columns: (e.attrs || []).map(a => columnToLegacy(e, a, [])),
        view: e.kind === 'view' || e.kind === 'materialized view' || undefined,
        definition: e.def,
        primaryKey: e.pk ? primaryKeyToLegacy(e.pk) : undefined,
        uniques: uniques.length > 0 ? uniques.map(uniqueToLegacy) : undefined,
        indexes: indexes.length > 0 ? indexes.map(indexToLegacy) : undefined,
        checks: e.checks ? e.checks.map(checkToLegacy) : undefined,
        comment: e.doc,
        stats: e.stats ? tableDbStatsToLegacy(e.stats) : undefined,
    })
}

export function tableDbStatsFromLegacy(s: LegacyTableDbStats): EntityStats {
    return removeUndefined({
        rows: s.rows,
        size: s.size,
        sizeIdx: s.sizeIdx,
        scanSeq: s.scanSeq,
        scanSeqLast: s.scanSeqLast,
        scanIdx: s.scanIdx,
        scanIdxLast: s.scanIdxLast,
        analyzeLast: s.analyzeLast,
        vacuumLast: s.vacuumLast,
    })
}

export function tableDbStatsToLegacy(s: EntityStats): LegacyTableDbStats {
    return removeUndefined({
        rows: s.rows,
        size: s.size,
        sizeIdx: s.sizeIdx,
        scanSeq: s.scanSeq,
        scanSeqLast: s.scanSeqLast,
        scanIdx: s.scanIdx,
        scanIdxLast: s.scanIdxLast,
        analyzeLast: s.analyzeLast,
        vacuumLast: s.vacuumLast,
    })
}

function columnFromLegacy(c: LegacyColumn): Attribute {
    return removeUndefined({
        name: c.name,
        type: c.type,
        null: c.nullable || undefined,
        default: c.default ? columnValueFromLegacy(c.default) : undefined,
        attrs: c.columns ? c.columns.map(columnFromLegacy) : undefined,
        doc: c.comment || undefined,
        stats: c.stats || c.values ? removeUndefined({
            nulls: c.stats?.nulls,
            bytesAvg: c.stats?.bytesAvg,
            cardinality: c.stats?.cardinality,
            commonValues: c.stats?.commonValues?.map(v => ({value: columnValueFromLegacy(v.value), freq: v.freq})),
            distinctValues: c.values?.map(columnValueFromLegacy),
            histogram: c.stats?.histogram?.map(columnValueFromLegacy),
            min: undefined,
            max: undefined,
        }) : undefined,
    })
}

function columnToLegacy(e: Entity, a: Attribute, parents: string[]): LegacyColumn {
    try {
        return removeEmpty({
            name: a.name,
            type: a.type,
            nullable: a.null,
            default: a.default ? columnValueToLegacy(a.default) : undefined,
            comment: a.doc,
            values: a.stats?.distinctValues?.map(columnValueToLegacy),
            columns: a.attrs?.map(aa => columnToLegacy(e, aa, [...parents, a.name])),
            stats: a.stats ? attributeDbStatsToLegacy(a.stats) : undefined,
        })
    } catch (err) {
        throw new Error(`Error in columnToLegacy for entity ${entityToId(e)} and attribute ${attributePathToId([...parents, a.name])}: ${errorToString(err)}`)
    }
}

export function columnValueFromLegacy(v: LegacyColumnValue): AttributeValue {
    return v
}

export function columnValueToLegacy(v: AttributeValue): LegacyColumnValue {
    return attributeValueToString(v)
}

export function attributeDbStatsToLegacy(s: AttributeStats): LegacyColumnDbStats {
    return removeUndefined({
        nulls: s.nulls,
        bytesAvg: s.bytesAvg,
        cardinality: s.cardinality,
        commonValues: s.commonValues?.map(v => ({value: columnValueToLegacy(v.value), freq: v.freq})),
        histogram: s.histogram?.map(columnValueToLegacy),
    })
}

export function primaryKeyFromLegacy(pk: LegacyPrimaryKey): PrimaryKey {
    return removeUndefined({
        name: pk.name || undefined,
        attrs: pk.columns.map(columnNameFromLegacy)
    })
}
export function primaryKeyToLegacy(pk: PrimaryKey): LegacyPrimaryKey {
    return removeUndefined({
        name: pk.name,
        columns: pk.attrs.map(columnNameToLegacy)
    })
}

export function columnNameFromLegacy(n: LegacyColumnName): AttributePath {
    return n.split(legacyColumnPathSeparator)
}

export function columnNameToLegacy(p: AttributePath): LegacyColumnName {
    return p.join(legacyColumnPathSeparator)
}

export function uniqueFromLegacy(u: LegacyUnique): Index {
    return removeUndefined({
        name: u.name || undefined,
        attrs: u.columns.map(columnNameFromLegacy),
        unique: true,
        definition: u.definition || undefined,
    })
}

export function uniqueToLegacy(i: Index): LegacyUnique {
    return removeUndefined({
        name: i.name,
        columns: i.attrs.map(columnNameToLegacy),
        definition: i.definition
    })
}

export function indexFromLegacy(i: LegacyIndex): Index {
    return removeUndefined({
        name: i.name || undefined,
        attrs: i.columns.map(columnNameFromLegacy),
        definition: i.definition || undefined,
    })
}

export function indexToLegacy(i: Index): LegacyIndex {
    return removeUndefined({
        name: i.name,
        columns: i.attrs.map(columnNameToLegacy),
        definition: i.definition
    })
}

export function checkFromLegacy(c: LegacyCheck): Check {
    return removeUndefined({
        name: c.name || undefined,
        attrs: c.columns.map(columnNameFromLegacy),
        predicate: c.predicate || '',
    })
}

export function checkToLegacy(c: Check): LegacyCheck {
    return removeUndefined({
        name: c.name,
        columns: c.attrs.map(columnNameToLegacy),
        predicate: c.predicate || undefined
    })
}

export function relationFromLegacy(r: LegacyRelation): Relation {
    return removeUndefined({
        name: r.name || undefined,
        src: {...columnRefFromLegacy2(r.src), attrs: [r.src.column.split(legacyColumnPathSeparator)]},
        ref: {...columnRefFromLegacy2(r.ref), attrs: [r.ref.column.split(legacyColumnPathSeparator)]},
    })
}

function relationToLegacy(r: Relation): LegacyRelation[] {
    return zip(r.src.attrs, r.ref.attrs).map(([srcAttr, refAttr]) => ({ name: r.name || '', src: columnRefToLegacy2(r.src, srcAttr), ref: columnRefToLegacy2(r.ref, refAttr) }))
}

export function tableRefFromId(id: LegacyTableId): LegacyTableRef {
    const [schema, table] = id.split('.')
    return table ? {schema, table} : {schema: '', table: schema}
}

export function tableRefToId(ref: LegacyTableRef): LegacyTableId {
    return `${ref.schema}.${ref.table}`
}

export function columnRefFromLegacy(c: LegacyColumnRef): AttributeRef {
    // FIXME: use function from ColumnName to AttributePath
    const {schema, table} = tableRefFromId(c.table)
    return removeUndefined({schema: schema || undefined, entity: table, attribute: [c.column]})
}

export function columnRefToLegacy(a: AttributeRef): LegacyColumnRef {
    // FIXME: use function from AttributePath to ColumnName
    return {table: tableRefToId({schema: a.schema || '', table: a.entity}), column: a.attribute.join(legacyColumnPathSeparator)}
}

function columnRefFromLegacy2(e: LegacyColumnRef): EntityRef {
    const {schema, table} = tableRefFromId(e.table)
    return removeUndefined({schema: schema || undefined, entity: table})
}

function columnRefToLegacy2(e: EntityRef, c: AttributePath): LegacyColumnRef {
    return {table: tableRefToId({schema: e.schema || '', table: e.entity}), column: c.join(legacyColumnPathSeparator)}
}

export function typeFromLegacy(t: LegacyType): Type {
    if ('values' in t) {
        return removeUndefined({schema: t.schema || undefined, name: t.name, values: t.values || undefined})
    } else {
        return removeUndefined({schema: t.schema || undefined, name: t.name, definition: t.definition})
    }
}

function typeToLegacy(t: Type): LegacyType {
    if (t.values) {
        return {schema: t.schema || '', name: t.name, values: t.values}
    } else {
        return {schema: t.schema || '', name: t.name, definition: t.definition || ''}
    }
}

export function legacyDatabaseJsonFormat(database: LegacyDatabase): string {
    return stringify(database, (path: (string | number)[], value: any) => {
        const last = path[path.length - 1]
        // if (last === 'tables' || last === 'relations' || last === 'types') return 0
        if (path.includes('columns') && last !== 'columns') return 0
        if (path.includes('primaryKey')) return 0
        if (path.includes('uniques') && path.length > 3) return 0
        if (path.includes('indexes') && path.length > 3) return 0
        if (path.includes('checks') && path.length > 3) return 0
        if (path.includes('relations') && path.length > 2) return 0
        if (path.includes('types') && path.length > 1) return 0
        return 2
    })
}
