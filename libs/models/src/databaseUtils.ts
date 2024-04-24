import {filterValues, groupBy, indexBy, mapValues, removeUndefined} from "@azimutt/utils";
import {
    AttributeId,
    AttributePath,
    AttributePathId,
    AttributeRef,
    AttributeType,
    AttributeTypeParsed,
    Entity,
    EntityId,
    EntityRef,
    Namespace,
    NamespaceId,
    Relation,
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

export const entityToRef = (e: Entity): EntityRef => removeUndefined({database: e.database, catalog: e.catalog, schema: e.schema, entity: e.name})
export const entityToId = (e: Entity): EntityId => entityRefToId(entityToRef(e))

export const attributePathToId = (path: AttributePath): AttributePathId => path.join('.')
export const attributePathFromId = (path: AttributePathId): AttributePath => path.split('.')

export const attributeRefToId = (ref: AttributeRef): AttributeId => `${entityRefToId(ref)}(${ref.attribute})`

export const attributeRefFromId = (id: AttributeId): AttributeRef => {
    const [, entityId, attributeId] = id.match(/^(.*)\((.*)\)$/) || []
    const entity = entityRefFromId(entityId || id)
    const attribute = attributePathFromId(attributeId || '')
    return {...entity, attribute}
}

export const attributeTypeParse = (type: AttributeType): AttributeTypeParsed => {
    return {full: type, kind: 'unknown'}
}

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

export const indexEntities = (entities: Entity[]): Record<EntityId, Entity> =>
    indexBy(entities, entityToId)
export const indexRelations = (relations: Relation[]): Record<EntityId, Record<EntityId, Relation[]>> =>
    mapValues(groupBy(relations, r => entityRefToId(r.src)), rels => groupBy(rels, r => entityRefToId(r.ref)))
export const indexTypes = (types: Type[]): Record<TypeId, Type> =>
    indexBy(types, typeToId)
