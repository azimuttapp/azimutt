import {
    Attribute,
    AttributePath,
    attributePathSame,
    AttributeValue,
    Check,
    Database,
    Entity,
    EntityRef,
    entityRefSame,
    entityToRef,
    Index,
    Namespace,
    Relation,
    Type
} from "@azimutt/models";

export function generatePostgres(database: Database): string {
    const types = (database.types || []).map(genType).join('')
    const entities = (database.entities || []).map(e => {
        const ref = entityToRef(e)
        const entityRelations = (database.relations || []).filter(r => entityRefSame(r.src, ref))
        return genEntity(e, entityRelations)
    })
    return (types ? types + '\n' : '') + entities.join('\n')
}

function genNamespace(n: Namespace): string {
    const database = n.database ? genIdentifier(n.database) + '.' : ''
    const catalog = n.catalog ? genIdentifier(n.catalog) + '.' : ''
    const schema = n.schema ? genIdentifier(n.schema) + '.' : ''
    return database + catalog + schema
}

function genEntity(e: Entity, relations: Relation[]): string {
    if (e.kind === 'view') return genView(e)
    return genTable(e, relations)
}

function genTable(e: Entity, relations: Relation[]): string {
    const attrs = (e.attrs || []).map(a => genAttribute(a, e, relations))
    const pk = e.pk && e.pk.attrs.length > 1 ? [`${e.pk.name ? `CONSTRAINT ${genIdentifier(e.pk.name)} ` : ''}PRIMARY KEY (${e.pk.attrs.map(genAttributePath).join(', ')})`] : []
    const indexes = (e.indexes || []).filter(i => !i.unique).map(i => genIndexCommand(i, e)).join('')
    const uniques = (e.indexes || []).filter(i => i.unique && i.attrs.length > 1).map(genUniqueEntity) // TODO: also unique on a single column when there is several
    const checks = (e.checks || []).filter(c => c.attrs.length > 1).map(genCheckEntity) // TODO: also check on a single column when there is several
    const rels = relations.filter(r => r.attrs.length > 1).map(r => genRelationEntity(r))
    const comments = [genCommentEntity(e), ...(e.attrs || []).map(a => genCommentAttribute(a, e))].filter(c => !!c).join('')
    const inner = attrs.concat(pk, uniques, checks, rels).map(v => '  ' + v).join(',\n')
    return `CREATE TABLE ${genNamespace(e)}${genIdentifier(e.name)} (${inner ? '\n' + inner + '\n' : ''});\n${indexes}${comments}`
}

function genView(e: Entity): string {
    return `CREATE VIEW ${genNamespace(e)}${genIdentifier(e.name)} (.... TODO ...);\n`
}

function genAttribute(a: Attribute, e: Entity, relations: Relation[]): string {
    const notNull = a.null || (e.pk?.attrs.find(aa => attributePathSame(aa, [a.name]))) ? '' : ' NOT NULL'
    const df = a.default ? ` DEFAULT ${genAttributeValue(a.default)}` : ''
    const pk = e.pk && e.pk.attrs.length === 1 && attributePathSame(e.pk.attrs[0], [a.name]) ? ` ${e.pk.name ? `CONSTRAINT ${genIdentifier(e.pk.name)} ` : ''}PRIMARY KEY` : ''
    const attrUniques = (e.indexes || []).filter(u => u.unique && u.attrs.length === 1 && attributePathSame(u.attrs[0], [a.name]))
    const unique = attrUniques.length === 1 ? ' UNIQUE' : ''
    const attrChecks = (e.checks || []).filter(c => c.attrs.length === 1 && attributePathSame(c.attrs[0], [a.name]))
    const check = attrChecks.length === 1 ? genCheckInline(attrChecks[0]) : ''
    const attrRelations = relations.filter(r => r.attrs.length === 1 && attributePathSame(r.attrs[0].src, [a.name]))
    const relation = attrRelations.length === 1 ? genRelationInline(attrRelations[0]) : ''
    return `${genIdentifier(a.name)} ${a.type}${notNull}${df}${pk}${unique}${check}${relation}`
}

function genIndexCommand(i: Index, e: Entity) {
    const name = i.name || `${e.name}_${i.attrs.map(a => a.join('')).join('_')}_${i.unique ? 'uniq' : 'idx'}`
    return `CREATE ${i.unique ? 'UNIQUE ' : ''}INDEX ${name} ON ${genNamespace(e)}${genIdentifier(e.name)}(${i.attrs.map(genAttributePath).join(', ')});\n`
}

function genUniqueEntity(u: Index): string {
    const name = u.name ? `CONSTRAINT ${genIdentifier(u.name)} ` : ''
    return `${name}UNIQUE (${u.attrs.map(genAttributePath).join(', ')})`
}

function genCheckInline(c: Check): string {
    return ` CHECK (${c.predicate})`
}

function genCheckEntity(c: Check): string {
    const name = c.name ? `CONSTRAINT ${genIdentifier(c.name)} ` : ''
    return `${name}CHECK (${c.predicate})`
}

function genAttributePath(p: AttributePath): string {
    const [head, ...tail] = p
    return head + tail.map(a => `->'${a}'`).join('')
}

function genRelationInline(relation: Relation): string {
    return ` REFERENCES ${genEntityRef(relation.ref)}(${relation.attrs.map(a => getAttributePath(a.ref)).join(', ')})`
}

function genRelationEntity(relation: Relation): string {
    const name = relation.name ? `CONSTRAINT ${genIdentifier(relation.name)} ` : ''
    const src = relation.attrs.map(a => genAttributePath(a.src)).join(', ')
    const refTable = `${genNamespace(relation.ref)}${genIdentifier(relation.ref.entity)}`
    const refAttrs = relation.attrs.map(a => genAttributePath(a.ref)).join(', ')
    return `${name}FOREIGN KEY (${src}) REFERENCES ${refTable}(${refAttrs})`
}

function genType(t: Type): string {
    const comment = genCommentType(t)
    return `CREATE TYPE ${genNamespace(t)}${genIdentifier(t.name)}${genTypeContent(t)};\n${comment}`
}

function genTypeContent(t: Type): string {
    if (t.values) return ` AS ENUM (${t.values.map(v => "'" + v + "'").join(', ')})`
    if (t.attrs) return ` AS (${t.attrs.map(a => genIdentifier(a.name) + ' ' + a.type).join(', ')})`
    if (t.definition) return ` ${t.definition}`
    return ''
}

function genCommentEntity(e: Entity): string {
    return e.doc ? `COMMENT ON TABLE ${genNamespace(e)}${genIdentifier(e.name)} IS ${genString(e.doc)};\n` : ''
}

function genCommentAttribute(a: Attribute, e: Entity): string {
    return a.doc ? `COMMENT ON COLUMN ${genNamespace(e)}${genIdentifier(e.name)}.${genIdentifier(a.name)} IS ${genString(a.doc)};\n` : ''
}

function genCommentType(t: Type): string {
    return t.doc ? `COMMENT ON TYPE ${genNamespace(t)}${genIdentifier(t.name)} IS ${genString(t.doc)};\n` : ''
}

function genEntityRef(ref: EntityRef): string {
    return `${genNamespace(ref)}${genIdentifier(ref.entity)}`
}

function getAttributePath(p: AttributePath): string {
    return p.map(genIdentifier).join('.')
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
    return str
}

function genString(str: string): string {
    return `'${str.replaceAll(/'/g, "''")}'`
}
