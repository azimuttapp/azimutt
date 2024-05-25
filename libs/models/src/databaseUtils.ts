import {arraySame, filterValues, groupBy, indexBy, mapValues, removeUndefined} from "@azimutt/utils";
import {
    Attribute,
    AttributeId,
    AttributePath,
    AttributePathId,
    AttributeRef,
    AttributesRef,
    AttributeType,
    AttributeTypeParsed,
    AttributeValue,
    Entity,
    EntityId,
    EntityRef,
    Namespace,
    NamespaceId,
    Relation,
    RelationId,
    Type,
    TypeId,
    TypeRef
} from "./database";

export const namespaceToId = (n: Namespace): NamespaceId => [
    n.database || '',
    n.catalog || '',
    n.schema || ''
].map(addQuotes).join('.').replace(/^\.+/, '')

export const namespaceFromId = (id: NamespaceId): Namespace => {
    const [schema, catalog, ...database] = id.split('.').reverse().map(removeQuotes)
    return filterValues({database: database.reverse().join('.'), catalog, schema}, v => !!v)
}

export const entityRefToId = (ref: EntityRef): EntityId => {
    const ns = namespaceToId(ref)
    return ns ? `${ns}.${ref.entity}` : addQuotes(ref.entity)
}

export const entityRefFromId = (id: EntityId): EntityRef => {
    const [entity, schema, catalog, ...database] = id.split('.').reverse().map(removeQuotes)
    const namespace = filterValues({database: database.reverse().join('.'), catalog, schema}, v => !!v)
    return {...namespace, entity}
}

export const entityRefSame = (a: EntityRef, b: EntityRef): boolean => a.entity === b.entity && a.schema === b.schema && a.catalog === b.catalog && a.database === b.database

export const entityToRef = (e: Entity): EntityRef => removeUndefined({database: e.database, catalog: e.catalog, schema: e.schema, entity: e.name})
export const entityToId = (e: Entity): EntityId => entityRefToId(entityToRef(e))

export const entityRefFromAttribute = (a: AttributeRef): EntityRef => {
    const {attribute, ...ref} = a
    return ref
}

export const attributePathToId = (path: AttributePath): AttributePathId => path.join('.')
export const attributePathFromId = (path: AttributePathId): AttributePath => path.split('.')
export const attributePathSame = (p1: AttributePath, p2: AttributePath): boolean => arraySame(p1, p2, (i1, i2) => i1 === i2)

export const attributeRefToId = (ref: AttributeRef): AttributeId => `${entityRefToId(ref)}(${attributePathToId(ref.attribute)})`

export const attributeRefFromId = (id: AttributeId): AttributeRef => {
    const [, entityId, attributeId] = id.match(/^(.*)\((.*)\)$/) || []
    const entity = entityRefFromId(entityId || id)
    const attribute = attributePathFromId(attributeId || '')
    return {...entity, attribute}
}

export const attributeRefToEntity = ({attribute, ...ref}: AttributeRef): EntityRef => ref
export const attributeRefSame = (a: AttributeRef, b: AttributeRef): boolean => entityRefSame(a, b) && attributePathSame(a.attribute, b.attribute)

export const attributesRefToId = (ref: AttributesRef): AttributeId => `${entityRefToId(ref)}(${ref.attributes.map(attributePathToId).join(', ')})`

export const attributesRefFromId = (id: AttributeId): AttributesRef => {
    const [, entityId, attributeId] = id.match(/^(.*)\((.*)\)$/) || []
    const entity = entityRefFromId(entityId || id)
    const attributes = (attributeId || '').split(',').map(a => attributePathFromId(a.trim()))
    return {...entity, attributes}
}

export const attributesRefSame = (a: AttributesRef, b: AttributesRef): boolean => entityRefSame(a, b) && arraySame(a.attributes, b.attributes, attributePathSame)

export const attributeTypeParse = (type: AttributeType): AttributeTypeParsed => ({full: type, kind: 'unknown'})

export const typeRefToId = (ref: TypeRef): TypeId => {
    const ns = namespaceToId(ref)
    return ns ? `${ns}.${ref.type}` : addQuotes(ref.type)
}

export const typeRefFromId = (id: TypeId): TypeRef => {
    const [type, schema, catalog, ...database] = id.split('.').reverse().map(removeQuotes)
    const namespace = filterValues({database: database.reverse().join('.'), catalog, schema}, v => !!v)
    return {...namespace, type}
}

export const typeToRef = (t: Type): TypeRef => removeUndefined({database: t.database, catalog: t.catalog, schema: t.schema, type: t.name})
export const typeToId = (t: Type): TypeId => typeRefToId(typeToRef(t))

export const entityAttributesToId = (entity: EntityRef, attributes: AttributePath[]): string => `${entityRefToId(entity)}(${attributes.map(attributePathToId).join(', ')})`
export const relationToId = (r: Relation): RelationId => `${entityAttributesToId(r.src, r.attrs.map(a => a.src))}->${entityAttributesToId(r.ref, r.attrs.map(a => a.ref))}`

function addQuotes(value: string): string {
    if (value.match(/^\w*$/)) {
        return value
    } else {
        return `"${value}"`
    }
}

function removeQuotes(value: string): string {
    if (value.startsWith('"') && value.endsWith('"')) {
        return value.slice(1, -1)
    } else {
        return value
    }
}

export function getAttribute(attrs: Attribute[] | undefined, path: AttributePath): Attribute | undefined {
    const [head, ...tail] = path
    const attr = (attrs || []).find(a => a.name == head)
    if (attr && tail.length === 0) {
        return attr
    } else if (attr && tail.length > 0) {
        return getAttribute(attr.attrs || [], tail)
    } else {
        return undefined
    }
}

export function getPeerAttributes(attrs: Attribute[] | undefined, path: AttributePath): Attribute[] {
    const [head, ...tail] = path
    if (attrs && tail.length > 0) {
        const attr = (attrs || []).find(a => a.name == head)
        return getPeerAttributes(attr?.attrs, tail)
    } else {
        return attrs || []
    }
}

export function flattenAttribute(attr: Attribute, p: AttributePath = []): {path: AttributePath, attr: Attribute}[] {
    const path = [...p, attr.name]
    return [{path, attr}, ...(attr.attrs || []).flatMap(a => flattenAttribute(a, path))]
}

export function attributeValueToString(value: AttributeValue): string {
    if (typeof value === 'string') return value
    if (typeof value === 'number') return value.toString()
    if (typeof value === 'boolean') return value.toString()
    if (value instanceof Date) return value.toISOString()
    if (value === null) return  'null'
    return JSON.stringify(value)
}

export const indexEntities = (entities: Entity[]): Record<EntityId, Entity> =>
    indexBy(entities, entityToId)
export const indexRelations = (relations: Relation[]): Record<EntityId, Record<EntityId, Relation[]>> =>
    mapValues(groupBy(relations, r => entityRefToId(r.src)), rels => groupBy(rels, r => entityRefToId(r.ref)))
export const indexTypes = (types: Type[]): Record<TypeId, Type> =>
    indexBy(types, typeToId)
