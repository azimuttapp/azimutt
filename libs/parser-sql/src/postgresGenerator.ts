import {equalDeep, indexBy, joinLast} from "@azimutt/utils";
import {
    Attribute,
    AttributeDiff,
    AttributePath,
    attributePathSame,
    AttributeType,
    AttributeValue,
    Check,
    Database,
    DatabaseDiff,
    Entity,
    EntityDiff,
    EntityRef,
    entityRefSame,
    entityToRef,
    Index,
    namespace,
    Namespace,
    PrimaryKey,
    Relation,
    Type,
    TypeDiff,
    TypeId,
    typeToId
} from "@azimutt/models";

export function generatePostgres(database: Database): string {
    const typesById = indexBy(database.types || [], typeToId)
    const drops = (database.entities || []).map(genEntityDrop).reverse().join('')
    const types = (database.types || []).map(genType).join('')
    let lineComments = database.extra?.comments || []
    const entities = (database.entities || []).map(e => {
        const ref = entityToRef(e)
        const entityRelations = (database.relations || []).filter(r => entityRefSame(r.src, ref))
        const entityComments = lineComments.filter(c => c.line < (e.extra?.line || 0))
        lineComments = lineComments.slice(entityComments.length)
        const comments = entityComments.length > 0 ? entityComments.map(c => c.comment ? `-- ${c.comment}\n` : '--\n').join('') + '\n' : ''
        return comments + genEntity(e, entityRelations, typesById)
    }).join('\n')
    return [drops, types, entities].filter(v => !!v).join('\n')
}

export function generatePostgresDiff(diff: DatabaseDiff): string {
    // TODO: rename types? (search in deleted if some created are identical except the name)
    const createdTypes = diff.types?.created?.map(genType) || []
    const updatedTypes = diff.types?.updated?.map(genTypeAlter) || []
    const deletedTypes = diff.types?.deleted?.map(genTypeDrop) || []
    const types = createdTypes.concat(updatedTypes, deletedTypes).join('')

    // TODO: rename entities? (search in deleted if some created are identical except the name)
    const createdEntities = diff.entities?.created?.map(e => genEntity(e, [], {})) || []
    const updatedEntities = diff.entities?.updated?.map(e => genEntityAlter(e, [], {})) || []
    const deletedEntities = diff.entities?.deleted?.map(genEntityDrop) || []
    const entities = createdEntities.concat(updatedEntities, deletedEntities).join('\n')

    return [types, entities].filter(v => !!v).join('\n')
}

function genNamespace(n: Namespace): string {
    // database & catalog are not handled in PostgreSQL
    return n.schema ? genIdentifier(n.schema) + '.' : ''
}

function genEntityDrop(e: Entity) {
    return `DROP ${e.kind === 'view' ? 'VIEW' : 'TABLE'} IF EXISTS ${genEntityIdentifier(e)};\n`
}

function genEntity(e: Entity, relations: Relation[], typesById: Record<TypeId, Type>): string {
    if (e.kind === 'view') return genView(e)
    return genTable(e, relations, typesById)
}

function genTable(e: Entity, relations: Relation[], typesById: Record<TypeId, Type>): string {
    const comment = e.extra?.comment ? `-- ${e.extra.comment}\n` : ''
    const attrs = (e.attrs || []).map(a => genAttribute(a, e.pk, e.indexes || [], e.checks || [], relations, typesById))
    const pk = e.pk && e.pk.attrs.length > 1 ? [{value: `${e.pk.name ? `CONSTRAINT ${genIdentifier(e.pk.name)} ` : ''}PRIMARY KEY (${e.pk.attrs.map(genAttributePath).join(', ')})`}] : []
    const indexes = (e.indexes || []).filter(i => !i.unique).map(i => genIndexCommand(i, e)).join('')
    const uniques = (e.indexes || []).filter(i => i.unique && i.attrs.length > 1).map(genUniqueEntity) // TODO: also unique on a single column when there is several
    const checks = (e.checks || []).filter(c => c.attrs.length > 1).map(genCheckEntity) // TODO: also check on a single column when there is several
    const rels = relations.filter(r => r.src.attrs.length > 1).map(r => genRelationEntity(r))
    const comments = [genCommentTable(e), ...(e.attrs || []).map(a => genCommentAttribute(a, e))].filter(c => !!c).join('')
    const inner = attrs.concat(pk, uniques, checks, rels).map(({value, comment}, i, arr) => '  ' + value + (arr[i + 1] ? `,` : '') + (comment ? ' -- ' + comment : '') + '\n').join('')
    return comment + `CREATE TABLE ${genEntityIdentifier(e)} (${inner ? '\n' + inner : ''});\n${indexes}${comments}`
}

function genView(e: Entity): string {
    const comments = [genCommentView(e), ...(e.attrs || []).map(a => genCommentAttribute(a, e))].filter(c => !!c).join('')
    if (e.def) {
        return `CREATE VIEW ${genEntityIdentifier(e)} AS\n${e.def};\n${comments}`
    } else {
        return `-- CREATE VIEW ${genEntityIdentifier(e)} AS <missing definition>;\n${comments}`
    }
}

function genEntityIdentifier(e: Namespace & { name: string }): string {
    return `${genNamespace(e)}${genIdentifier(e.name)}`
}

type TableInner = {value: string, comment?: string | undefined}

function genAttribute(a: Attribute, pk: PrimaryKey | undefined, indexes: Index[], checks: Check[], relations: Relation[], typesById: Record<TypeId, Type>): TableInner {
    const [type, typeComment] = genAttributeType(a.type, typesById)
    const notNull = a.null || (pk?.attrs.find(aa => attributePathSame(aa, [a.name]))) ? '' : ' NOT NULL'
    const df = a.default ? ` DEFAULT ${genAttributeValue(a.default)}` : ''
    const primaryKey = pk && pk.attrs.length === 1 && attributePathSame(pk.attrs[0], [a.name]) ? ` ${pk.name ? `CONSTRAINT ${genIdentifier(pk.name)} ` : ''}PRIMARY KEY` : ''
    const attrUniques = indexes.filter(u => u.unique && u.attrs.length === 1 && attributePathSame(u.attrs[0], [a.name]))
    const unique = attrUniques.length === 1 ? ' UNIQUE' : ''
    const attrChecks = checks.filter(c => c.attrs.length === 1 && attributePathSame(c.attrs[0], [a.name]))
    const [check, checkComment] = attrChecks.length === 1 ? genCheckInline(attrChecks[0]) : ['', '']
    const attrRelations = relations.filter(r => r.src.attrs.length === 1 && attributePathSame(r.src.attrs[0], [a.name]))
    const [relation, relComment] = attrRelations.length === 1 ? genRelationInline(attrRelations[0]) : ['', '']
    const relComment2 = attrRelations.length > 1 ? `references: ${joinLast(attrRelations.map(r => `${genEntityRef(r.ref)}.${showAttributePath(r.ref.attrs[0])}${r.polymorphic ? ` (${showAttributePath(r.polymorphic.attribute)}=${genAttributeValue(r.polymorphic.value)})` : ''}`), ', ', ' or ')}` : ''
    const comment = [typeComment, checkComment, relComment, relComment2, a.extra?.comment || ''].filter(c => !!c).join(', ')
    return {value: `${genIdentifier(a.name)} ${type}${notNull}${df}${primaryKey}${unique}${check}${relation}`, comment}
}

function genAttributeType(type: AttributeType, typesById: Record<TypeId, Type>): [string, string] {
    // TODO: also look for type with entity namespace?
    const t = typesById[type]
    if (t && t.alias) {
        return [t.alias, `type alias '${type}'`]
    } else {
        return [type, '']
    }
}

function genIndexCommand(i: Index, e: Entity) {
    const name = i.name || `${e.name}_${i.attrs.map(a => a.join('')).join('_')}_${i.unique ? 'uniq' : 'idx'}`
    return `CREATE ${i.unique ? 'UNIQUE ' : ''}INDEX ${name} ON ${genEntityIdentifier(e)}(${i.attrs.map(genAttributePathIndex).join(', ')});\n`
}

function genUniqueEntity(u: Index): TableInner {
    const name = u.name ? `CONSTRAINT ${genIdentifier(u.name)} ` : ''
    return {value: `${name}UNIQUE (${u.attrs.map(genAttributePath).join(', ')})`}
}

function genCheckInline(c: Check): [string, string] {
    return c.predicate ? [` ${c.name ? `CONSTRAINT ${c.name} ` : ''}CHECK (${c.predicate})`, ''] : ['', 'check constraint but no predicate']
}

function genCheckEntity(c: Check): TableInner {
    const name = c.name ? `CONSTRAINT ${genIdentifier(c.name)} ` : ''
    return {value: `${name}CHECK (${c.predicate})`}
}

function genEntityAlter(e: EntityDiff, relations: Relation[], typesById: Record<TypeId, Type>): string {
    if (e.kind.after !== e.kind.before) {
        // drop & create
        return `TODO ${e.kind.before || 'table'} -> ${e.kind.after || 'table'}`
    } else if (e.kind.after === 'view') {
        return genViewAlter(e)
    } else {
        return genTableAlter(e, relations, typesById)
    }
}

function genTableAlter(e: EntityDiff, relations: Relation[], typesById: Record<TypeId, Type>): string { // see https://www.postgresql.org/docs/current/sql-altertable.html
    return [
        genEntityAlterAttributes(e, relations, typesById),
        e.doc ? [genComment('TABLE', genEntityIdentifier(e), e.doc.after)] : [],
    ].flat().join('')
}

function genViewAlter(e: EntityDiff): string { // see https://www.postgresql.org/docs/current/sql-alterview.html
    // TODO improve
    return [
        e.doc ? [genComment('VIEW', genEntityIdentifier(e), e.doc.after)] : [],
    ].flat().join('')
}

function genEntityAlterAttributes(e: EntityDiff, relations: Relation[], typesById: Record<TypeId, Type>): string[] {
    if (e.attrs) {
        const renamed = e.attrs.deleted?.flatMap(d => {
            const replace = e.attrs?.created?.find(c => c.i === d.i)
            return replace && equalDeep(d, {...replace, name: d.name}) ? [{i: d.i, name: {before: d.name, after: replace.name}}] : []
        }) || []
        return [
            renamed.map(r => `ALTER TABLE ${genTypeIdentifier(e)} RENAME ${r.name.before} TO ${r.name.after};\n`),
            e.attrs.updated?.flatMap(a => genEntityAlterAttribute(a, e, relations, typesById)),
            e.attrs.created?.flatMap(a => renamed.find(r => r.i === a.i) ? [] : [`ALTER TABLE ${genTypeIdentifier(e)} ADD ${genAttribute(a, undefined, [], [], relations, typesById).value};\n`]),
            e.attrs.deleted?.flatMap(a => renamed.find(r => r.i === a.i) ? [] : [`ALTER TABLE ${genTypeIdentifier(e)} DROP ${a.name};\n`]),
        ].flat()
    }
    return []
}

function genEntityAlterAttribute(a: AttributeDiff, e: EntityDiff, relations: Relation[], typesById: Record<TypeId, Type>): string[] {
    return [
        a.type?.after ? [`ALTER TABLE ${genTypeIdentifier(e)} ALTER ${a.name} TYPE ${a.type.after};\n`] : [],
        a.null ? [`ALTER TABLE ${genTypeIdentifier(e)} ALTER ${a.name} ${a.null.after ? 'DROP' : 'SET'} NOT NULL;\n`] : [],
        a.default ? [`ALTER TABLE ${genTypeIdentifier(e)} ALTER ${a.name} ${a.default.after === undefined ? 'DROP DEFAULT' : `SET DEFAULT ${genAttributeValue(a.default.after)}`};\n`] : [],
    ].flat()
}

function genRelationInline(relation: Relation): [string, string] {
    if (relation.ref.attrs.some(a => a.length > 1)) {
        return ['', `reference nested attribute ${genEntityRef(relation.ref)}(${relation.ref.attrs.map(showAttributePath).join(', ')})`]
    } else {
        return [` REFERENCES ${genEntityRef(relation.ref)}(${relation.ref.attrs.map(genAttributePath).join(', ')})`, '']
    }
}

function genRelationEntity(relation: Relation): TableInner {
    const name = relation.name ? `CONSTRAINT ${genIdentifier(relation.name)} ` : ''
    const src = relation.src.attrs.map(genAttributePath).join(', ')
    const refTable = `${genNamespace(relation.ref)}${genIdentifier(relation.ref.entity)}`
    const refAttrs = relation.ref.attrs.map(genAttributePath).join(', ')
    return {value: `${name}FOREIGN KEY (${src}) REFERENCES ${refTable}(${refAttrs})`}
}

function genTypeIdentifier(t: Namespace & { name: string }): string {
    return `${genNamespace(t)}${genIdentifier(t.name)}`
}

function genType(t: Type): string {
    const content = genTypeContent(t)
    const comment = genCommentType(t)
    return `${t.alias ? '-- ' : ''}CREATE TYPE ${genTypeIdentifier(t)}${content};${t.alias ? ' -- type alias not supported on PostgreSQL' : ''}\n${comment}`
}

function genTypeContent(t: Type): string {
    if (t.alias) return  ` AS ${t.alias}` // fake syntax, will be commented
    if (t.values) return ` AS ENUM (${t.values.map(v => "'" + v + "'").join(', ')})`
    if (t.attrs) return ` AS (${t.attrs.map(a => genIdentifier(a.name) + ' ' + a.type).join(', ')})`
    if (t.definition) return ` ${t.definition}`
    return ''
}

function genTypeAlter(t: TypeDiff): string { // see https://www.postgresql.org/docs/current/sql-altertype.html
    return [
        getTypeAlterAlias(t),
        genTypeAlterEnum(t),
        getTypeAlterStruct(t),
        getTypeAlterCustom(t),
        t.doc ? [genComment('TYPE', genTypeIdentifier(t), t.doc.after)] : [],
    ].flat().join('')
}

function getTypeAlterAlias(t: TypeDiff): string[] {
    if (t.alias?.after) {
        if (t.alias.before) { // was already an alias
            return [`-- ALTER TYPE ${genTypeIdentifier(t)} AS ${t.alias.after}; -- type alias not supported on PostgreSQL\n`]
        } else { // was something else
            return [genTypeDrop(t), genType({...namespace(t), name: t.name, alias: t.alias.after})]
        }
    }
    return []
}

function genTypeAlterEnum(t: TypeDiff): string[] {
    if (t.values?.after) {
        if (t.values.before) { // already enum
            return t.values.after.flatMap(v => t.values?.before?.includes(v) ? [] : [`ALTER TYPE ${genTypeIdentifier(t)} ADD VALUE IF NOT EXISTS ${genString(v)};\n`])
                .concat(t.values.before.flatMap(v => t.values?.after?.includes(v) ? [] : [`-- ALTER TYPE ${genTypeIdentifier(t)} DROP VALUE ${genString(v)}; -- can't drop enum value in PostgreSQL\n`]))
        } else { // was something else
            return [genTypeDrop(t), genType({...namespace(t), name: t.name, values: t.values.after})]
        }
    }
    return []
}

function getTypeAlterStruct(t: TypeDiff): string[] {
    if (t.attrs) {
        if (t.alias || t.values || t.values || t.definition) { // was not a struct
            return [genTypeDrop(t), genType({...namespace(t), name: t.name, attrs: t.attrs.created})]
        } else {
            const renamed = t.attrs.deleted?.flatMap(d => {
                const replace = t.attrs?.created?.find(c => c.i === d.i)
                return replace && equalDeep(d, {...replace, name: d.name}) ? [{i: d.i, name: {before: d.name, after: replace.name}}] : []
            }) || []
            return [
                renamed.map(r => `ALTER TYPE ${genTypeIdentifier(t)} RENAME ATTRIBUTE ${r.name.before} TO ${r.name.after};\n`),
                t.attrs.updated?.flatMap(a => a.type?.after ? [`ALTER TYPE ${genTypeIdentifier(t)} ALTER ATTRIBUTE ${a.name} TYPE ${a.type.after};\n`] : []),
                t.attrs.created?.flatMap(a => renamed.find(r => r.i === a.i) ? [] : [`ALTER TYPE ${genTypeIdentifier(t)} ADD ATTRIBUTE ${a.name} ${a.type};\n`]),
                t.attrs.deleted?.flatMap(a => renamed.find(r => r.i === a.i) ? [] : [`ALTER TYPE ${genTypeIdentifier(t)} DROP ATTRIBUTE IF EXISTS ${a.name};\n`]),
            ].flat()
        }
    }
    return []
}

function getTypeAlterCustom(t: TypeDiff): string[] {
    if (t.definition?.after) { // can't update custom types, so drop & create
        return [genTypeDrop(t), genType({...namespace(t), name: t.name, definition: t.definition.after})]
    }
    return []
}

function genTypeDrop(t: Namespace & { name: string }): string {
    return `DROP TYPE IF EXISTS ${genTypeIdentifier(t)};\n`
}

function genCommentTable(e: Entity): string {
    return e.doc ? genComment('TABLE', genEntityIdentifier(e), e.doc) : ''
}

function genCommentView(e: Entity): string {
    return e.doc ? genComment('VIEW', genEntityIdentifier(e), e.doc) : ''
}

function genCommentAttribute(a: Attribute, e: Entity): string {
    return a.doc ? genComment('COLUMN', `${genEntityIdentifier(e)}.${genIdentifier(a.name)}`, a.doc) : ''
}

function genCommentType(t: Type): string {
    return t.doc ? genComment('TYPE', genTypeIdentifier(t), t.doc) : ''
}

function genComment(kind: 'TABLE' | 'VIEW' | 'COLUMN' | 'TYPE', identifier: string, value: string | undefined): string {
    return `COMMENT ON ${kind} ${identifier} IS ${value ? genString(value) : 'NULL'};\n`
}

function genEntityRef(ref: EntityRef): string {
    return `${genNamespace(ref)}${genIdentifier(ref.entity)}`
}

function genAttributePath(p: AttributePath): string {
    const [head, ...tail] = p
    return head + tail.map(a => `->'${a}'`).join('')
}

function genAttributePathIndex(p: AttributePath): string {
    const [head, ...tail] = p
    if (tail.length > 0) {
        return '(' + head + tail.map((a, i) => (tail[i + 1] ? '->' : '->>') + `'${a}'`).join('') + ')'
    } else {
        return head
    }
}

function showAttributePath(p: AttributePath): string {
    return p.join('.')
}

function genAttributeValue(v: AttributeValue): string {
    if (v === undefined) return ''
    if (v === null) return 'NULL'
    if (typeof v === 'string') return v.startsWith('`') ? v.slice(1, -1) : genString(v)
    if (typeof v === 'number') return v.toString()
    if (typeof v === 'boolean') return v ? 'TRUE' : 'FALSE'
    return `${v}`
}

function genIdentifier(str: string): string {
    if (str.match(/^[a-zA-Z_][a-zA-Z0-9_$]*$/)) return str
    return '"' + str + '"'
}

function genString(str: string): string {
    if (str.indexOf('\n') !== -1) {
        return `E'${str.replaceAll(/'/g, "''").replaceAll(/\n/g, '\\n')}'`
    } else {
        return `'${str.replaceAll(/'/g, "''")}'`
    }
}
