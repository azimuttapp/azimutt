import {Attribute, attributePathToId, AttributeValue, Database, Entity, Index, Relation, Type} from "@azimutt/models";
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
import {AttributeExtra, DatabaseExtra, EntityExtra, Group, IndexExtra, RelationExtra, TypeExtra} from "./extra";
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
    const pkComposite: JsonIndex[] = entity.pk && entity.pk.attrs.length > 1 ? [{
        columns: entity.pk.attrs.map(c => ({type: 'column', value: attributePathToId(c)})),
        pk: true,
        note: null
    }] : []
    return removeUndefined({
        name: entity.name,
        alias: extra.alias || null,
        note: entity.doc || null,
        headerColor: extra.color || undefined,
        fields: (entity.attrs || []).map(c => exportAttribute(c, entity)),
        indexes: pkComposite.concat((entity.indexes || []).filter(i => i.attrs.length > 1 || !i.unique || i.name).map(exportIndex))
    })
}

function exportAttribute(attribute: Attribute, entity: Entity): JsonField {
    const extra: AttributeExtra = AttributeExtra.parse(attribute.extra) || {}
    return removeUndefined({
        name: attribute.name,
        type: { schemaName: null, type_name: attribute.type, args: null },
        pk: entity.pk?.attrs.map(attributePathToId).includes(attribute.name) && entity.pk?.attrs.length === 1 || false,
        unique: entity.indexes?.some(i => i.unique && i.attrs.map(attributePathToId).includes(attribute.name)) || false,
        not_null: attribute.null === false ? true : undefined,
        increment: extra.increment || undefined,
        dbdefault: attribute.default !== undefined ? exportAttributeDefault(attribute.default, extra.defaultType as JsonFieldDefaultType) : undefined,
        note: attribute.doc || null
    })
}

function exportAttributeDefault(d: AttributeValue, type: JsonFieldDefaultType | undefined): JsonFieldDefault | undefined {
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
        columns: index.attrs.map(attributePathToId).map(c => ({type: (extra.attrTypes || {})[c] || 'column', value: c})),
        unique: index.unique,
        type: index.definition,
        note: index.doc || null
    })
}

function exportRelation(relation: Relation): JsonRef {
    const extra: RelationExtra = RelationExtra.parse(relation.extra) || {}
    return removeUndefined({
        name: relation.name || null,
        endpoints: [{
            schemaName: relation.ref.schema || null,
            tableName: relation.ref.entity,
            fieldNames: relation.attrs.map(c => attributePathToId(c.ref)),
            relation: relation.kind?.endsWith('many') ? '*' : '1'
        }, {
            schemaName: relation.src.schema || null,
            tableName: relation.src.entity,
            fieldNames: relation.attrs.map(c => attributePathToId(c.src)),
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
        note: type.doc || null
    }
}

function exportGroup(group: Group): JsonGroup {
    return {
        name: group.name,
        tables: group.entities.map(t => ({schemaName: t.schema || defaultSchema, tableName: t.entity}))
    }
}
