import {arraySame, filterValues, groupBy, indexBy, mapValues, removeUndefined, stringify} from "@azimutt/utils";
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
    ConstraintId,
    ConstraintRef,
    Database,
    Entity,
    EntityId,
    EntityRef,
    Namespace,
    NamespaceId,
    Relation,
    RelationId,
    RelationRef,
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

export const entityRefSame = (a: EntityRef, b: EntityRef): boolean =>
    (a.entity === b.entity || a.entity === '*' || b.entity === '*') &&
    (a.schema === b.schema || a.schema === '*' || b.schema === '*') &&
    (a.catalog === b.catalog || a.catalog === '*' || b.catalog === '*') &&
    (a.database === b.database || a.database === '*' || b.database === '*')

export const entityToRef = (e: Entity): EntityRef => removeUndefined({database: e.database, catalog: e.catalog, schema: e.schema, entity: e.name})
export const entityToId = (e: Entity): EntityId => entityRefToId(entityToRef(e))

export const entityRefFromAttribute = (a: AttributeRef): EntityRef => {
    const {attribute, ...ref} = a
    return ref
}

export const attributePathToId = (path: AttributePath): AttributePathId => path.join('.')
export const attributePathFromId = (path: AttributePathId): AttributePath => path.split('.')
export const attributePathSame = (p1: AttributePath, p2: AttributePath): boolean => arraySame(p1, p2, (i1, i2) => i1 === i2 || i1 === '*' || i2 === '*')

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
    const [, entityId, attributeId] = id.match(/^([^(]*)\(([^)]*)\)$/) || []
    const entity = entityRefFromId(entityId || id)
    const attributes = (attributeId || '').split(',').map(a => attributePathFromId(a.trim()))
    return {...entity, attributes}
}

export const attributesRefSame = (a: AttributesRef, b: AttributesRef): boolean => entityRefSame(a, b) && arraySame(a.attributes, b.attributes, attributePathSame)

export const constraintRefToId = (ref: ConstraintRef): ConstraintId => `${entityRefToId(ref)}(${ref.constraint})`

export const constraintRefFromId = (id: ConstraintId): ConstraintRef => {
    const [, entityId, constraintName] = id.match(/^(.*)\((.*)\)$/) || []
    const entity = entityRefFromId(entityId || id)
    return {...entity, constraint: constraintName}
}

export const constraintRefSame = (a: ConstraintRef, b: ConstraintRef): boolean => entityRefSame(a, b) && (a.constraint === b.constraint || a.constraint === '*' || b.constraint === '*')

// similar to frontend/src/Models/Project/ColumnType.elm
export const attributeTypeParse = (type: AttributeType): AttributeTypeParsed => {
    let res
    if (type.endsWith('[]')) return {...attributeTypeParse(type.slice(0, -2)), array: true}
    if (res = /^array<(.*)>$/gi.exec(type)) {
        const [, subType] = res
        return {...attributeTypeParse(subType), array: true}
    }
    if (res = /^(?:n)?(var)?(?:bit|string|(?:bp)?char(?:acter)?)(\s+varying)?(?:\((\d+)\))?(?:\s+character set ([^ ]+))?$/gi.exec(type)) {
        const [, var1, var2, size, encoding] = res
        return removeUndefined({full: type, kind: 'string' as const, size: size ? parseInt(size) : undefined, variable: var1 || var2 ? true : undefined, encoding})
    }
    if (/^(tiny|medium|long|ci)?text$/gi.exec(type)) return {full: type, kind: 'string', variable: true}
    if (res = /^(tiny|small|big)?(?:int(?:eger)?|serial)(2|4|8|64)?(?:\((\d+)\))?(?:\s+unsigned)?$/gi.exec(type)) {
        const [, textSize, size] = res
        return removeUndefined({full: type, kind: 'int' as const, size: size === '64' ? 8 : size ? parseInt(size) : textSize ? parseSize(textSize) : 4})
    }
    if (res = /^(?:real|float)([248])?$/gi.exec(type)) {
        const [, size] = res
        return {full: type, kind: 'float', size: size ? parseInt(size) : 4}
    }
    if (/^double precision$/gi.exec(type)) return {full: type, kind: 'float', size: 8}
    if (/^(?:decimal|numeric|number)(\s*\(\s*\d+\s*,\s*\d+\s*\))?$/gi.exec(type)) return {full: type, kind: 'float'}
    if (/^bool(?:ean)?$/gi.exec(type)) return {full: type, kind: 'bool'}
    if (/^date$/gi.exec(type)) return {full: type, kind: 'date', size: 4}
    if (res = /^time(tz)?(\s+with time zone)?(\s+without time zone)?$/gi.exec(type)) {
        const [, tz, hasTz] = res
        return {full: type, kind: 'time', size: tz || hasTz ? 12 : 8}
    }
    if (/^timestamp(tz)?(?:\((\d+)\))?(\s+with time zone)?(\s+without time zone)?$/gi.exec(type)) return {full: type, kind: 'instant', size: 8}
    if (/^datetime$/gi.exec(type)) return {full: type, kind: 'instant'}
    if (/^interval(?:\((\d+)\))?(\s+'[^']+')?$/gi.exec(type)) return {full: type, kind: 'period', size: 16}
    if (/^bytea$/gi.exec(type)) return {full: type, kind: 'binary'}
    if (/^(tiny|medium|long)?blob$/gi.exec(type)) return {full: type, kind: 'binary', variable: true}
    if (/^uuid$/gi.exec(type)) return {full: type, kind: 'uuid'}
    if (/^jsonb?$/gi.exec(type)) return {full: type, kind: 'json'}
    if (/^xml$/gi.exec(type)) return {full: type, kind: 'xml'}
    return {full: type, kind: 'unknown'}
}

const parseSize = (textSize: string): number | undefined => textSize === 'tiny' ? 1 : textSize === 'small' ? 2 : textSize === 'big' ? 8 : undefined

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

export const relationToRef = (r: Relation): RelationRef => ({src: {...r.src, attributes: r.attrs.map(a => a.src)}, ref: {...r.ref, attributes: r.attrs.map(a => a.ref)}})
export const relationToId = (r: Relation): RelationId => relationRefToId(relationToRef(r))

export const relationRefToId = (ref: RelationRef): RelationId => `${attributesRefToId(ref.src)}->${attributesRefToId(ref.ref)}`

export const relationRefFromId = (id: RelationId): RelationRef => {
    const [, src, ref] = id.match(/^([^(]*\([^)]*\))->([^(]*\([^)]*\))$/) || []
    return {src: attributesRefFromId(src), ref: attributesRefFromId(ref)}
}

export const relationRefSame = (a: RelationRef, b: RelationRef): boolean => attributesRefSame(a.src, b.src) && attributesRefSame(a.ref, b.ref)

function addQuotes(value: string): string {
    if (value.match(/^\w*$/)) {
        return value
    } else {
        return `"${value}"`
    }
}

export function removeQuotes(value: string): string {
    if (value.startsWith('"') && value.endsWith('"')) {
        return value.slice(1, -1)
    } else if (value.startsWith("'") && value.endsWith("'")) {
        return value.slice(1, -1)
    } else if (value.startsWith("`") && value.endsWith("`")) {
        return value.slice(1, -1)
    } else if (value.startsWith("[") && value.endsWith("]")) { // SQL Server way ^^
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

export function databaseJsonFormat(database: Database): string {
    return stringify(database, (path: (string | number)[], value: any) => {
        const last = path[path.length - 1]
        // if (last === 'entities' || last === 'relations') return 0
        if (path.includes('attrs') && last !== 'attrs') return 0
        if (path.includes('pk')) return 0
        if (path.includes('indexes') && path.length > 3) return 0
        if (path.includes('checks') && path.length > 3) return 0
        if (path.includes('relations') && path.length > 2) return 0
        if (path.includes('types') && path.length > 1) return 0
        if (path.includes('stats')) return 0
        if (path.includes('extra') && path.length > 1) return 0
        return 2
    })
}
