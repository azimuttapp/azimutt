import {
    arraySame,
    distinct,
    errorToString,
    filterKeys,
    filterValues,
    groupBy,
    indexBy,
    mapValues,
    mergeBy,
    removeEmpty,
    removeUndefined,
    stringify
} from "@azimutt/utils";
import {zodParse} from "./zod";
import {
    Attribute,
    AttributeExtra,
    attributeExtraKeys,
    AttributeId,
    AttributePath,
    AttributePathId,
    AttributeRef,
    AttributesRef,
    AttributeType,
    AttributeTypeParsed,
    AttributeValue,
    Check,
    ConstraintId,
    ConstraintRef,
    Database,
    DatabaseExtra,
    databaseExtraKeys,
    Entity,
    EntityExtra,
    entityExtraKeys,
    EntityId,
    EntityRef,
    Index,
    IndexExtra,
    indexExtraKeys,
    Namespace,
    NamespaceId,
    PrimaryKey,
    Relation,
    RelationExtra,
    relationExtraKeys,
    RelationId,
    RelationLink,
    RelationRef,
    Type,
    TypeExtra,
    typeExtraKeys,
    TypeId,
    TypeRef
} from "./database";
import {ParserResult} from "./parserResult";
import {legacyColumnTypeUnknown} from "./legacy/legacyDatabase";

export const namespace = (n: Namespace) => removeUndefined({database: n.database, catalog: n.catalog, schema: n.schema})

export const namespaceToId = (n: Namespace): NamespaceId => [
    n.database || '',
    n.catalog || '',
    n.schema || ''
].map(addQuotes).join('.').replace(/^\.+/, '')

export const namespaceFromId = (id: NamespaceId): Namespace => {
    const [schema, catalog, ...database] = id.split('.').reverse().map(removeQuotes)
    return filterValues({database: database.reverse().join('.'), catalog, schema}, v => !!v)
}

export const namespaceSame = (a: Namespace, b: Namespace): boolean =>
    (a.schema === b.schema || a.schema === '*' || b.schema === '*') &&
    (a.catalog === b.catalog || a.catalog === '*' || b.catalog === '*') &&
    (a.database === b.database || a.database === '*' || b.database === '*')

export const entityRefToId = (ref: EntityRef): EntityId => {
    const ns = namespaceToId(ref)
    return ns ? `${ns}.${ref.entity}` : addQuotes(ref.entity)
}

export const entityRefFromId = (id: EntityId): EntityRef => {
    const [entity, schema, catalog, ...database] = id.split('.').reverse().map(removeQuotes)
    const namespace = filterValues({database: database.reverse().join('.'), catalog, schema}, v => !!v)
    return {...namespace, entity}
}

export const entityRefSame = (a: EntityRef, b: EntityRef): boolean => (a.entity === b.entity || a.entity === '*' || b.entity === '*') && namespaceSame(a, b)
export const entityToNamespace = (e: Entity): Namespace => namespace(e)
export const entityToRef = (e: Entity): EntityRef => removeUndefined({...namespace(e), entity: e.name})
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

export const attributesRefToId = (ref: AttributesRef): AttributeId => `${entityRefToId(ref)}(${ref.attrs.map(attributePathToId).join(', ')})`

export const attributesRefFromId = (id: AttributeId): AttributesRef => {
    const [, entityId, attributeId] = id.match(/^([^(]*)\(([^)]*)\)$/) || []
    const entity = entityRefFromId(entityId || id)
    const attrs = (attributeId || '').split(',').map(a => attributePathFromId(a.trim()))
    return {...entity, attrs}
}

export const attributesRefSame = (a: AttributesRef, b: AttributesRef): boolean => entityRefSame(a, b) && arraySame(a.attrs, b.attrs, attributePathSame)

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

export const typeRefSame = (a: TypeRef, b: TypeRef): boolean =>
    (a.type === b.type || a.type === '*' || b.type === '*') &&
    (a.schema === b.schema || a.schema === '*' || b.schema === '*') &&
    (a.catalog === b.catalog || a.catalog === '*' || b.catalog === '*') &&
    (a.database === b.database || a.database === '*' || b.database === '*')

export const typeToNamespace = (t: Type): Namespace => namespace(t)
export const typeToRef = (t: Type): TypeRef => removeUndefined({...namespace(t), type: t.name})
export const typeToId = (t: Type): TypeId => typeRefToId(typeToRef(t))

export const relationLinkToEntityRef = (l: RelationLink): EntityRef => removeUndefined({...namespace(l), entity: l.entity})
export const relationLinkToAttributeRef = (l: RelationLink): AttributesRef => ({...relationLinkToEntityRef(l), attrs: l.attrs})
export const relationToRef = (r: Relation): RelationRef => ({src: relationLinkToAttributeRef(r.src), ref: relationLinkToAttributeRef(r.ref)})
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

export function flattenAttributes(attrs: Attribute[] | undefined): (Attribute & {path: AttributePath})[] {
    return (attrs || []).flatMap(a => flattenAttribute(a))
}

function flattenAttribute(attr: Attribute, p: AttributePath = []): (Attribute & {path: AttributePath})[] {
    const path = [...p, attr.name]
    return [{...attr, path}, ...(attr.attrs || []).flatMap(a => flattenAttribute(a, path))]
}

export function attributeValueToString(value: AttributeValue): string {
    if (value === null) return  'null'
    if (value === undefined) return  'null'
    if (typeof value === 'string') return value
    if (typeof value === 'number') return value.toString()
    if (typeof value === 'bigint') return value.toString()
    if (typeof value === 'boolean') return value.toString()
    if (value instanceof String) return value.toString()
    if (value instanceof Number) return value.toString()
    if (value instanceof Boolean) return value.toString()
    if (value instanceof Date) return isNaN(value.getTime()) ? 'null' : value.toISOString()
    return JSON.stringify(value) || 'null'
}

export const indexEntities = (entities: Entity[]): Record<EntityId, Entity> =>
    indexBy(entities, entityToId)
export const indexRelations = (relations: Relation[]): Record<EntityId, Record<EntityId, Relation[]>> =>
    mapValues(groupBy(relations, r => entityRefToId(r.src)), rels => groupBy(rels, r => entityRefToId(r.ref)))
export const indexTypes = (types: Type[]): Record<TypeId, Type> =>
    indexBy(types, typeToId)

export function parseJsonDatabase(content: string): ParserResult<Database> {
    let json: any = undefined
    try {
        json = JSON.parse(content)
    } catch (e) {
        return ParserResult.failure([{message: errorToString(e), kind: 'MalformedJson', level: 'error', offset: {start: 0, end: 0}, position: {start: {line: 0, column: 0}, end: {line: 0, column: 0}}}])
    }
    return zodParse(Database)(json).fold(
        db => ParserResult.success(db),
        err => ParserResult.failure([{message: err, kind: 'InvalidJson', level: 'error', offset: {start: 0, end: 0}, position: {start: {line: 0, column: 0}, end: {line: 0, column: 0}}}])
    )
}

export function generateJsonDatabase(database: Database): string {
    return stringify(database, (path: (string | number)[], value: any) => {
        const last = path[path.length - 1]
        // if (last === 'entities' || last === 'relations' || last === 'types') return 0
        if (path.includes('attrs') && last !== 'attrs') return 0
        if (path.includes('pk')) return 0
        if (path.includes('indexes') && path.length > 3) return 0
        if (path.includes('checks') && path.length > 3) return 0
        if (path.includes('relations') && path.length > 2) return 0
        if (path.includes('types') && path.length > 1) return 0
        if (path.includes('stats')) return 0
        if (path.includes('extra') && (path[0] !== 'extra' || path.length > 3)) return 0
        return 2
    }) + '\n'
}


// the first database has priority on the second one when it makes sense
export function mergeDatabase(a: Database, b: Database): Database {
    return removeEmpty({
        entities: mergeBy(a.entities || [], b.entities || [], entityToId, mergeEntity),
        relations: mergeBy(a.relations || [], b.relations || [], relationToId, mergeRelation),
        types: mergeBy(a.types || [], b.types || [], typeToId, mergeType),
        doc: a.doc || b.doc,
        stats: mergeStats(a.stats, b.stats),
        extra: mergeDatabaseExtra(a.extra, b.extra),
    })
}

export function mergeDatabaseExtra(a: DatabaseExtra | undefined, b: DatabaseExtra | undefined): DatabaseExtra | undefined {
    if (a === undefined) return b
    if (b === undefined) return a
    const extra = filterKeys(Object.assign({}, b || {}, a || {}), k => !databaseExtraKeys.includes(k.toString())) // a should overrides b
    return removeUndefined({
        source: mergeOneOrSame(a.source, b.source),
        createdAt: mergeOneOrSame(a.createdAt, b.createdAt),
        creationTimeMs: mergeOneOrSame(a.creationTimeMs, b.creationTimeMs),
        comments: a.comments && b.comments ? a.comments.concat(b.comments) : a.comments || b.comments, // keep all comments
        namespaces: a.namespaces && b.namespaces ? undefined : a.namespaces || b.namespaces, // remove if defined in both
        ...extra
    })
}

export function mergeEntity(a: Entity, b: Entity): Entity {
    return removeUndefined({
        database: a.database, // keep the 'a' reference (database, catalog, schema, name), should be the same as b
        catalog: a.catalog,
        schema: a.schema,
        name: a.name,
        kind: a.kind, // don't change kind, undefined means table
        def: a.def || b.def,
        attrs: a.attrs && b.attrs ? mergeBy(a.attrs, b.attrs, attr => attr.name, mergeAttribute) : a.attrs || b.attrs,
        pk: a.pk && b.pk ? mergePrimaryKey(a.pk, b.pk) : a.pk || b.pk,
        indexes: a.indexes && b.indexes ? mergeBy(a.indexes, b.indexes, i => i.attrs.map(attributePathToId).join(','), mergeIndex) : a.indexes || b.indexes,
        checks: a.checks && b.checks ? mergeBy(a.checks, b.checks, c => c.predicate + ':' + c.attrs.map(attributePathToId).join(','), mergeCheck) : a.checks || b.checks,
        doc: a.doc || b.doc,
        stats: mergeStats(a.stats, b.stats),
        extra: mergeEntityExtra(a.extra, b.extra),
    })
}

export function mergeEntityExtra(a: EntityExtra | undefined, b: EntityExtra | undefined): EntityExtra | undefined {
    if (a === undefined) return b
    if (b === undefined) return a
    const extra = filterKeys(Object.assign({}, b || {}, a || {}), k => !entityExtraKeys.includes(k.toString())) // a should overrides b
    return removeUndefined({
        line:a.line || b.line,
        statement: a.statement || b.statement,
        alias: a.alias || b.alias,
        color: a.color || b.color,
        tags: a.tags && b.tags ? distinct(a.tags.concat(b.tags)) : a.tags || b.tags,
        comment: a.comment || b.comment,
        ...extra
    })
}

export function mergeAttribute(a: Attribute, b: Attribute): Attribute {
    return removeUndefined({
        name: a.name, // keep the 'a' reference (name), should be the same as b
        type: a.type === '' || a.type === legacyColumnTypeUnknown ? b.type : a.type,
        null: a.null || b.null,
        gen: a.gen, // don't change unique, undefined means 'false'
        default: a.default || b.default,
        attrs: a.attrs && b.attrs ? mergeBy(a.attrs, b.attrs, attr => attr.name, mergeAttribute) : a.attrs || b.attrs,
        doc: a.doc || b.doc,
        stats: mergeStats(a.stats, b.stats),
        extra: mergeAttributeExtra(a.extra, b.extra),
    })
}

export function mergeAttributeExtra(a: AttributeExtra | undefined, b: AttributeExtra | undefined): AttributeExtra | undefined {
    if (a === undefined) return b
    if (b === undefined) return a
    const extra = filterKeys(Object.assign({}, b || {}, a || {}), k => !attributeExtraKeys.includes(k.toString())) // a should overrides b
    return removeUndefined({
        line:a.line || b.line,
        statement: a.statement || b.statement,
        autoIncrement: a.autoIncrement === undefined ? b.autoIncrement : a.autoIncrement,
        hidden: a.hidden === undefined ? b.hidden : a.hidden,
        tags: a.tags && b.tags ? distinct(a.tags.concat(b.tags)) : a.tags || b.tags,
        comment: a.comment || b.comment,
        ...extra
    })
}

export function mergePrimaryKey(a: PrimaryKey, b: PrimaryKey): PrimaryKey {
    return removeUndefined({
        name: a.name || b.name,
        attrs: a.attrs, // don't change primary key attrs
        doc: a.doc || b.doc,
        stats: mergeStats(a.stats, b.stats),
        extra: mergeIndexExtra(a.extra, b.extra),
    })
}

export function mergeIndex(a: Index, b: Index): Index {
    return removeUndefined({
        name: a.name || b.name,
        attrs: a.attrs, // keep the 'a' reference (attrs & predicate), should be the same as b
        unique: a.unique, // don't change unique, undefined means 'false'
        partial: a.partial, // don't change partial, undefined means 'false'
        definition: a.definition || b.definition,
        doc: a.doc || b.doc,
        stats: mergeStats(a.stats, b.stats),
        extra: mergeIndexExtra(a.extra, b.extra),
    })
}

export function mergeCheck(a: Check, b: Check): Check {
    return removeUndefined({
        name: a.name || b.name,
        attrs: a.attrs, // keep the 'a' reference (attrs & predicate), should be the same as b
        predicate: a.predicate,
        doc: a.doc || b.doc,
        stats: mergeStats(a.stats, b.stats),
        extra: mergeIndexExtra(a.extra, b.extra),
    })
}

export function mergeIndexExtra(a: IndexExtra | undefined, b: IndexExtra | undefined): IndexExtra | undefined {
    if (a === undefined) return b
    if (b === undefined) return a
    const extra = filterKeys(Object.assign({}, b || {}, a || {}), k => !indexExtraKeys.includes(k.toString())) // a should overrides b
    return removeUndefined({
        line:a.line || b.line,
        statement: a.statement || b.statement,
        ...extra
    })
}

export function mergeRelation(a: Relation, b: Relation): Relation {
    return removeUndefined({
        name: a.name || b.name,
        origin: a.origin, // don't change origin, undefined means 'fk'
        src: a.src, // keep the 'a' reference (src & ref), should be the same as b
        ref: a.ref,
        polymorphic: a.polymorphic || b.polymorphic,
        doc: a.doc || b.doc,
        extra: mergeRelationExtra(a.extra, b.extra),
    })
}

export function mergeRelationExtra(a: RelationExtra | undefined, b: RelationExtra | undefined): RelationExtra | undefined {
    if (a === undefined) return b
    if (b === undefined) return a
    const extra = filterKeys(Object.assign({}, b || {}, a || {}), k => !relationExtraKeys.includes(k.toString())) // a should overrides b
    return removeUndefined({
        line:a.line || b.line,
        statement: a.statement || b.statement,
        inline: mergeOneOrSame(a.inline, b.inline),
        natural: a.natural || b.natural,
        onUpdate: a.onUpdate || b.onUpdate,
        onDelete: a.onDelete || b.onDelete,
        srcAlias: a.srcAlias || b.srcAlias,
        refAlias: a.refAlias || b.refAlias,
        tags: a.tags && b.tags ? distinct(a.tags.concat(b.tags)) : a.tags || b.tags,
        comment: a.comment || b.comment,
        ...extra
    })
}

export function mergeType(a: Type, b: Type): Type {
    return removeUndefined({
        database: a.database, // keep the 'a' reference (database, catalog, schema, name), should be the same as b
        catalog: a.catalog,
        schema: a.schema,
        name: a.name,
        alias: a.alias || b.alias,
        values: a.values && b.values ? distinct(a.values.concat(b.values)) : a.values || b.values,
        attrs: a.attrs && b.attrs ? mergeBy(a.attrs, b.attrs, attr => attr.name, mergeAttribute) : a.attrs || b.attrs,
        definition: a.definition || b.definition,
        doc: a.doc || b.doc,
        extra: mergeTypeExtra(a.extra, b.extra),
    })
}

export function mergeTypeExtra(a: TypeExtra | undefined, b: TypeExtra | undefined): TypeExtra | undefined {
    if (a === undefined) return b
    if (b === undefined) return a
    const extra = filterKeys(Object.assign({}, b || {}, a || {}), k => !typeExtraKeys.includes(k.toString())) // a should overrides b
    return removeUndefined({
        line:a.line || b.line,
        statement: a.statement || b.statement,
        inline: mergeOneOrSame(a.inline, b.inline),
        tags: a.tags && b.tags ? distinct(a.tags.concat(b.tags)) : a.tags || b.tags,
        comment: a.comment || b.comment,
        ...extra
    })
}

export function mergeStats<T>(a: T | undefined, b: T | undefined): T | undefined {
    // keep stats only when just one db has them, otherwise discard them to avoid false stats on db but allow extending a db with stats
    if (a === undefined) return b
    if (b === undefined) return a
    return undefined
}

function mergeOneOrSame<T extends string | number | boolean>(a: T | undefined, b: T | undefined): T | undefined {
    if (a === undefined) return b
    if (b === undefined) return a
    if (a === b) return a
    return undefined // remove if defined differently in both
}
