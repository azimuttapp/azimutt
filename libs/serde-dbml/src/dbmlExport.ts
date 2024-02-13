import {Column, ColumnValue, Database, Entity, Index, Relation, Type} from "@azimutt/database-model";
import {groupBy, removeUndefined} from "@azimutt/utils";
import {
    JsonDatabase,
    JsonEnum,
    JsonField,
    JsonFieldDefault,
    JsonFieldDefaultType,
    JsonGroup,
    JsonIndex,
    JsonRef,
    JsonRefEndpoint,
    JsonSchema,
    JsonTable
} from "./jsonDatabase";
import {
    ColumnExtra,
    DatabaseExtra,
    Group,
    IndexExtra,
    RelationExtra,
    EntityExtra,
    TypeExtra
} from "./extra";
import {defaultSchema} from "./dbmlImport";

export function exportDatabase(db: Database): JsonDatabase {
    const extra: DatabaseExtra = DatabaseExtra.parse(db.extra) || {}
    const entitiesBySchema = groupBy(db.entities || [], t => t.schema || defaultSchema)
    const typesBySchema = groupBy(db.types || [], t => t.schema || defaultSchema)
    const groupsBySchema = groupBy((extra.groups || []) as Group[], g => g.schema || defaultSchema)
    const schemas = [...new Set(Object.keys(entitiesBySchema).concat(Object.keys(typesBySchema), Object.keys(groupsBySchema)))]
    return {
        schemas: schemas.map(schema => exportSchema(schema, entitiesBySchema[schema] || [], [], typesBySchema[schema] || [], groupsBySchema[schema] || []))
            .concat([exportSchema('relations', [], db.relations || [], [], [])]) // put relations in an other schema to avoid JSON parser bug
    }
}

function exportSchema(name: string, entities: Entity[], relations: Relation[], types: Type[], groups: Group[]): JsonSchema {
    return {
        name,
        tables: entities.map(exportEntity),
        refs: relations.map(exportRelation),
        enums: types.map(exportType),
        tableGroups: [] // groups.map(exportGroup) // FIXME: JSON parser fails with tableGroups (Error: Table "public".undefined don't exist)
    }
}

function exportEntity(entity: Entity): JsonTable {
    const extra: EntityExtra = EntityExtra.parse(entity.extra) || {}
    const pkComposite: JsonIndex[] = entity.primaryKey && entity.primaryKey.columns.length > 1 ? [{
        columns: entity.primaryKey.columns.map(c => ({type: 'column', value: c})),
        pk: true,
        note: null
    }] : []
    return removeUndefined({
        name: entity.name,
        alias: extra.alias || null,
        note: entity.comment || null,
        headerColor: extra.color || undefined,
        fields: entity.columns.map(c => exportColumn(c, entity)),
        indexes: pkComposite.concat((entity.indexes || []).filter(i => i.columns.length > 1 || !i.unique || i.name).map(exportIndex))
    })
}

function exportColumn(column: Column, entity: Entity): JsonField {
    const extra: ColumnExtra = ColumnExtra.parse(column.extra) || {}
    return removeUndefined({
        name: column.name,
        type: { schemaName: null, type_name: column.type, args: null },
        pk: entity.primaryKey?.columns.includes(column.name) && entity.primaryKey?.columns.length === 1 || false,
        unique: entity.indexes?.some(i => i.unique && i.columns.includes(column.name)) || false,
        not_null: column.nullable === false ? true : undefined,
        increment: extra.increment || undefined,
        dbdefault: column.default !== undefined ? exportColumnDefault(column.default, extra.defaultType as JsonFieldDefaultType) : undefined,
        note: column.comment || null
    })
}

function exportColumnDefault(d: ColumnValue, type: JsonFieldDefaultType | undefined): JsonFieldDefault | undefined {
    if (d === undefined) return undefined
    if (d === null) return { value: 'null', type: type || 'boolean' }
    if (d === 'null' || d === 'true' || d === 'false') return { value: d.toString(), type: type || 'boolean' }
    if (typeof d === 'string') return { value: d, type: type || 'string' }
    if (typeof d === 'number') return { value: d, type: type || 'number' }
    return { value: d.toString(), type: type || 'boolean' }
}

function exportIndex(index: Index): JsonIndex {
    const extra: IndexExtra = IndexExtra.parse(index.extra) || {}
    return removeUndefined({
        name: index.name,
        columns: index.columns.map(c => ({type: (extra.columnTypes || {})[c] || 'column', value: c})),
        unique: index.unique,
        type: index.definition,
        note: index.comment || null
    })
}

function exportRelation(relation: Relation): JsonRef {
    const extra: RelationExtra = RelationExtra.parse(relation.extra) || {}
    return removeUndefined({
        name: relation.name || null,
        endpoints: [{
            schemaName: relation.ref.schema || null,
            tableName: relation.ref.entity,
            fieldNames: relation.columns.map(c => c.ref),
            relation: relation.kind?.endsWith('many') ? '*' : '1'
        }, {
            schemaName: relation.src.schema || null,
            tableName: relation.src.entity,
            fieldNames: relation.columns.map(c => c.src),
            relation: relation.kind?.startsWith('one') ? '1' : '*'
        }] as [JsonRefEndpoint, JsonRefEndpoint],
        onDelete: extra.onDelete || undefined,
        onUpdate: extra.onUpdate || undefined
    })
}

function exportType(type: Type): JsonEnum {
    const extra: TypeExtra = TypeExtra.parse(type.extra) || {}
    const valueNotes: Record<string, string> = extra.notes || {}
    return {
        name: type.name,
        values: (type.values || []).map(v => ({name: v, note: valueNotes[v] || null})),
        note: type.comment || null
    }
}

function exportGroup(group: Group): JsonGroup {
    return {
        name: group.name,
        tables: group.entities.map(t => ({schemaName: t.schema || defaultSchema, tableName: t.entity}))
    }
}
