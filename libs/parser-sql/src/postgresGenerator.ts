import {equalDeep, indexBy, joinLast} from "@azimutt/utils";
import {
    ArrayDiff,
    Attribute,
    AttributeDiff,
    AttributePath,
    attributePathSame,
    AttributeType,
    AttributeValue,
    Check,
    CheckDiff,
    Database,
    DatabaseDiff,
    Entity,
    EntityDiff,
    EntityRef,
    entityRefSame,
    entityToRef,
    Index,
    IndexDiff,
    namespace,
    Namespace,
    OptValueDiff,
    PrimaryKey,
    Relation,
    RelationDiff,
    relationToId,
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
    const createdTypes = diff.types?.created?.map(genType) || []
    const updatedTypes = diff.types?.updated?.map(genTypeAlter) || []
    const deletedTypes = diff.types?.deleted?.map(genTypeDrop) || []
    const types = createdTypes.concat(updatedTypes, deletedTypes).join('')

    const createdEntities = diff.entities?.created?.map(e => genEntity(e, [], {})) || []
    const updatedEntities = diff.entities?.updated?.map(e => genEntityAlter(e, [], {})) || []
    const deletedEntities = diff.entities?.deleted?.map(genEntityDrop) || []
    const entities = createdEntities.concat(updatedEntities, deletedEntities).join('\n')

    const createdRelations = diff.relations?.created?.map(r => genRelation(r)) || []
    const updatedRelations = diff.relations?.updated?.flatMap(r => genRelationAlter(r)) || []
    const deletedRelations = diff.relations?.deleted?.map(genRelationDrop) || []
    const relations = createdRelations.concat(updatedRelations, deletedRelations).join('\n')

    return [types, entities, relations].filter(v => !!v).join('\n')
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
    const pk = e.pk && e.pk.attrs.length > 1 ? [{value: `${genConstraintName(e.pk.name)}PRIMARY KEY (${e.pk.attrs.map(genAttributePath).join(', ')})`}] : []
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

function genAttributeIdentifier(a: { name: string }, e: Namespace & { name: string }): string {
    return `${genEntityIdentifier(e)}.${genIdentifier(a.name)}`
}

type TableInner = {value: string, comment?: string | undefined}

function genAttribute(a: Attribute, pk: PrimaryKey | undefined, indexes: Index[], checks: Check[], relations: Relation[], typesById: Record<TypeId, Type>): TableInner {
    const [type, typeComment] = genAttributeType(a.type, typesById)
    const notNull = a.null || (pk?.attrs.find(aa => attributePathSame(aa, [a.name]))) ? '' : ' NOT NULL'
    const df = a.default ? ` DEFAULT ${genAttributeValue(a.default)}` : ''
    const primaryKey = pk && pk.attrs.length === 1 && attributePathSame(pk.attrs[0], [a.name]) ? ` ${genConstraintName(pk.name)}PRIMARY KEY` : ''
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
    return {value: `${genConstraintName(u.name)}UNIQUE (${u.attrs.map(genAttributePath).join(', ')})`}
}

function genCheckInline(c: Check): [string, string] {
    return c.predicate ? [` ${genConstraintName(c.name)}CHECK (${c.predicate})`, ''] : ['', 'check constraint but no predicate']
}

function genCheckEntity(c: Check): TableInner {
    return {value: `${genConstraintName(c.name)}CHECK (${c.predicate})`}
}

function genEntityAlter(e: EntityDiff, relations: Relation[], typesById: Record<TypeId, Type>): string {
    if (e.kind && e.kind.after !== e.kind.before) {
        // drop & create
        return `TODO ${e.kind.before || 'table'} -> ${e.kind.after || 'table'}`
    } else if (e.kind?.after === 'view') {
        return genViewAlter(e)
    } else {
        return genTableAlter(e, relations, typesById)
    }
}

function genTableAlter(e: EntityDiff, relations: Relation[], typesById: Record<TypeId, Type>): string {
    // see https://www.postgresql.org/docs/current/sql-altertable.html
    const res: string[] = []
    if (e.rename) {
        if (e.rename.before === undefined && e.rename.after) {
            res.push(`ALTER TABLE <missing old name> RENAME TO ${genIdentifier(e.rename.after)};\n`)
        } else if (e.rename.before && e.rename.after === undefined) {
            res.push(`ALTER TABLE ${genIdentifier(e.rename.before)} RENAME TO <missing new name>;\n`)
        } else if (e.rename.before && e.rename.after) {
            res.push(`ALTER TABLE ${genIdentifier(e.rename.before)} RENAME TO ${genIdentifier(e.rename.after)};\n`)
        }
    }
    return [
        res,
        genEntityAlterAttributes(e, relations, typesById),
        e.pk ? genEntityAlertPrimaryKey(e, e.pk) : [],
        e.indexes ? genEntityAlterIndexes(e, e.indexes) : [],
        e.checks ? genEntityAlterChecks(e, e.checks) : [],
        e.doc ? [genComment('TABLE', genEntityIdentifier(e), e.doc.after)] : [],
    ].flat().join('')
}

function genEntityAlertPrimaryKey(e: EntityDiff, pk: OptValueDiff<PrimaryKey>): string[] {
    if (pk.before === undefined && pk.after) {
        return [`ALTER TABLE ${genEntityIdentifier(e)} ADD ${genConstraintName(pk.after.name)}PRIMARY KEY (${pk.after.attrs.map(genAttributePathIndex).join(', ')});\n`]
    } else if (pk.before && pk.after === undefined) {
        if (pk.before.name) {
            return [`ALTER TABLE ${genEntityIdentifier(e)} DROP CONSTRAINT ${genIdentifier(pk.before.name)};\n`]
        } else {
            return [`-- ALTER TABLE ${genEntityIdentifier(e)} DROP CONSTRAINT -- missing primary key name\n`]
        }
    } else {
        if (pk.before && pk.before.name) {
            return [`-- ALTER TABLE ${genEntityIdentifier(e)} ALTER ${genConstraintName(pk.before.name)}-- missing props\n`]
        } else {
            return [`-- ALTER TABLE ${genEntityIdentifier(e)} ALTER CONSTRAINT -- missing primary key name and props\n`]
        }
    }
}

function genEntityAlterIndexes(e: EntityDiff, indexes: ArrayDiff<Index, IndexDiff>): string[] {
    return ([] as string[]).concat(
        (indexes.created || []).map(i => genIndexCreate(e, i)),
        (indexes.deleted || []).map(i => genIndexDrop(e, i)),
        (indexes.updated || []).flatMap(i => genIndexAlter(e, i)),
    )
}

function genIndexCreate(e: EntityDiff, i: Index): string {
    // see https://www.postgresql.org/docs/current/sql-createindex.html
    // see https://www.postgresql.org/docs/current/indexes-partial.html
    const def = i.definition ? i.definition : i.attrs.map(genAttributePathIndex).join(', ')
    const ref = i.name ? genIdentifier(i.name) : `<missing name for index on ${genEntityIdentifier(e)} (${i.attrs.map(genAttributePathIndex).join(', ')})>`
    const doc = i.doc ? genCommentIndex(i.name, ref, i.doc) : ''
    return `CREATE ${i.unique ? 'UNIQUE ' : ''}INDEX ${i.name ? genIdentifier(i.name) + ' ' : ''}ON ${genEntityIdentifier(e)} (${def})${i.partial ? ` WHERE ${i.partial}` : ''};\n${doc}`
}

function genIndexDrop(e: EntityDiff, i: Index): string {
    // see https://www.postgresql.org/docs/current/sql-dropindex.html
    if (i.name) {
        return `DROP INDEX ${i.name};\n`
    } else {
        return `-- DROP INDEX -- missing name for ${genEntityIdentifier(e)} (${i.attrs.map(genAttributePathIndex).join(', ')});\n`
    }
}

function genIndexAlter(e: EntityDiff, i: IndexDiff): string[] {
    // see https://www.postgresql.org/docs/current/sql-alterindex.html
    const res: string[] = []
    const name = i.name || i.rename?.after || i.rename?.before
    const ref = name ? genIdentifier(name) : `<missing name for index on ${genEntityIdentifier(e)} (${i.attrs.map(genAttributePathIndex).join(', ')})>`
    if (i.rename) {
        if (i.rename.before === undefined && i.rename.after) {
            res.push(`-- ALTER INDEX <missing old name> RENAME TO ${genIdentifier(i.rename.after)};\n`)
        } else if (i.rename.before && i.rename.after === undefined) {
            res.push(`-- ALTER INDEX ${genIdentifier(i.rename.before)} RENAME TO <missing new name>;\n`)
        } else if (i.rename.before && i.rename.after) {
            res.push(`ALTER INDEX ${genIdentifier(i.rename.before)} RENAME TO ${genIdentifier(i.rename.after)};\n`)
        }
    }
    if (i.unique) res.push(`-- ALTER INDEX ${ref} -- can't ${i.unique.after ? 'set' : 'drop'} UNIQUE on PostgreSQL\n`)
    if (i.partial) res.push(`-- ALTER INDEX ${ref} -- can't update index partial clause to (${i.partial.after}) on PostgreSQL\n`)
    if (i.definition) res.push(`-- ALTER INDEX ${ref} -- can't update index definition to (${i.definition.after}) on PostgreSQL\n`)
    if (i.doc) res.push(genCommentIndex(name, ref, i.doc.after))
    return res
}

function genCommentIndex(name: string | undefined, ref: string, doc: string | undefined): string {
    return (name ? '' : '-- ') + genComment('INDEX', ref, doc)
}

function genEntityAlterChecks(e: EntityDiff, checks: ArrayDiff<Check, CheckDiff>): string[] {
    return ([] as string[]).concat(
        (checks.created || []).map(c => genCheckCreate(e, c)),
        (checks.deleted || []).map(c => genCheckDrop(e, c)),
        (checks.updated || []).flatMap(c => genCheckAlter(e, c)),
    )
}

function genCheckCreate(e: EntityDiff, c: Check): string {
    // see https://www.postgresql.org/docs/current/sql-altertable.html
    const doc = c.doc ? genCommentCheck(c.name, c.name ? genIdentifier(c.name) : '<missing check name>', e, c.doc) : ''
    return `ALTER TABLE ${genEntityIdentifier(e)} ADD ${genConstraintName(c.name)}CHECK (${c.predicate});\n${doc}`
}

function genCheckDrop(e: EntityDiff, c: Check): string {
    // see https://www.postgresql.org/docs/current/sql-altertable.html
    if (c.name) {
        return `ALTER TABLE ${genEntityIdentifier(e)} DROP CONSTRAINT ${genIdentifier(c.name)};\n`
    } else {
        return `-- ALTER TABLE ${genEntityIdentifier(e)} DROP CONSTRAINT -- missing name for check (${c.predicate})\n`
    }
}

function genCheckAlter(e: EntityDiff, c: CheckDiff): string[] {
    const res: string[] = []
    const name = c.name || c.rename?.after || c.rename?.before
    const ref = name ? genIdentifier(name) : `<missing name for check>`
    if (c.rename) {
        if (c.rename.before === undefined && c.rename.after) {
            res.push(`-- ALTER TABLE ${genEntityIdentifier(e)} RENAME CONSTRAINT <missing old name> TO ${genIdentifier(c.rename.after)};\n`)
        } else if (c.rename.before && c.rename.after === undefined) {
            res.push(`-- ALTER TABLE ${genEntityIdentifier(e)} RENAME ${genConstraintName(c.rename.before)}TO <missing new name>;\n`)
        } else if (c.rename.before && c.rename.after) {
            res.push(`ALTER TABLE ${genEntityIdentifier(e)} RENAME ${genConstraintName(c.rename.before)}TO ${genIdentifier(c.rename.after)};\n`)
        }
    }
    if (c.predicate) res.push(`-- ALTER TABLE ${genEntityIdentifier(e)} ALTER CONSTRAINT ${ref} -- can't update check predicate to (${c.predicate.after}) on PostgreSQL\n`)
    if (c.doc) res.push(genCommentCheck(name, ref, e, c.doc.after))
    return res
}

function genCommentCheck(name: string | undefined, ref: string, e: Namespace & { name: string }, value: string | undefined): string {
    return (name ? '' : '-- ') + `COMMENT ON CONSTRAINT ${ref} ON ${genEntityIdentifier(e)} IS ${value ? genString(value) : 'NULL'};\n`
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
            e.attrs.created?.flatMap(a => renamed.find(r => r.i === a.i) ? [] : [`ALTER TABLE ${genTypeIdentifier(e)} ADD ${genAttribute(a, e.pk?.after, [], [], relations, typesById).value};\n`]),
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
        a.doc ? [genComment('COLUMN', genAttributeIdentifier(a, e), a.doc.after)] : [],
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
    const src = relation.src.attrs.map(genAttributePath).join(', ')
    const refTable = `${genNamespace(relation.ref)}${genIdentifier(relation.ref.entity)}`
    const refAttrs = relation.ref.attrs.map(genAttributePath).join(', ')
    return {value: `${genConstraintName(relation.name)}FOREIGN KEY (${src}) REFERENCES ${refTable}(${refAttrs})`}
}

function genRelation(relation: Relation): string {
    return `ALTER TABLE ${genEntityRef(relation.src)} ADD FOREIGN KEY (${relation.src.attrs.map(genAttributePath).join(', ')}) REFERENCES ${genEntityRef(relation.ref)}(${relation.ref.attrs.map(genAttributePath).join(', ')});\n`
}

function genRelationAlter(relation: RelationDiff): string[] {
    const res: string[] = []
    if (relation.rename) {
        if (relation.rename.before === undefined && relation.rename.after) {
            res.push(`-- ALTER TABLE ${genEntityRef(relation.src)} RENAME CONSTRAINT <missing old name> TO ${genIdentifier(relation.rename.after)};\n`)
        } else if (relation.rename.before && relation.rename.after === undefined) {
            res.push(`-- ALTER TABLE ${genEntityRef(relation.src)} RENAME CONSTRAINT ${genIdentifier(relation.rename.before)} TO <missing new name>;\n`)
        } else if (relation.rename.before && relation.rename.after) {
            res.push(`ALTER TABLE ${genEntityRef(relation.src)} RENAME CONSTRAINT ${genIdentifier(relation.rename.before)} TO ${genIdentifier(relation.rename.after)};\n`)
        }
    }
    return res
}

function genRelationDrop(relation: Relation): string {
    if (relation.name) {
        return `ALTER TABLE ${genEntityRef(relation.src)} DROP CONSTRAINT ${genIdentifier(relation.name)};\n`
    } else {
        return `-- ALTER TABLE ${genEntityRef(relation.src)} DROP CONSTRAINT -- missing name for ${relationToId(relation)}\n`
    }
}

function genConstraintName(name: string | undefined): string {
    return name ? `CONSTRAINT ${genIdentifier(name)} ` : ''
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
        genTypeRename(t),
        genTypeAlterAlias(t),
        genTypeAlterEnum(t),
        genTypeAlterStruct(t),
        genTypeAlterCustom(t),
        t.doc ? [genComment('TYPE', genTypeIdentifier(t), t.doc.after)] : [],
    ].flat().join('')
}

function genTypeRename(t: TypeDiff): string[] {
    if (t.rename) {
        if (t.rename.before === undefined && t.rename.after) {
            return [`-- ALTER TYPE <missing old name> RENAME TO ${genIdentifier(t.rename.after)};\n`]
        } else if (t.rename.before && t.rename.after === undefined) {
            return [`-- ALTER TYPE ${genIdentifier(t.rename.before)} RENAME TO <missing new name>;\n`]
        } else if (t.rename.before && t.rename.after) {
            return [`ALTER TYPE ${genIdentifier(t.rename.before)} RENAME TO ${genIdentifier(t.rename.after)};\n`]
        }
    }
    return []
}

function genTypeAlterAlias(t: TypeDiff): string[] {
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

function genTypeAlterStruct(t: TypeDiff): string[] {
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

function genTypeAlterCustom(t: TypeDiff): string[] {
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
    return a.doc ? genComment('COLUMN', genAttributeIdentifier(a, e), a.doc) : ''
}

function genCommentType(t: Type): string {
    return t.doc ? genComment('TYPE', genTypeIdentifier(t), t.doc) : ''
}

function genComment(kind: 'TABLE' | 'VIEW' | 'COLUMN' | 'INDEX' | 'TYPE', identifier: string, value: string | undefined): string {
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
