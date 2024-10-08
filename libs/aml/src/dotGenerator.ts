import {
    Attribute, AttributePath,
    attributePathSame,
    Database,
    Entity,
    EntityRef,
    entityRefSame,
    entityToRef,
    Relation
} from "@azimutt/models";

export function generateDot(database: Database, opts: {doc?: boolean} = {}): string {
    const entities = (database.entities || []).map(e => {
        const ref = entityToRef(e)
        const entityRelations = (database.relations || []).filter(r => entityRefSame(r.src, ref))
        return '\n' + genEntity(e, entityRelations, {doc: opts.doc === undefined ? true : opts.doc})
    }).join('')
    return genHeader(database) + entities + genFooter()
}

const indent = '    '

function genHeader(db: Database) {
    const name = db.stats?.name
    const def = `digraph ${name ? genIdentifier(name) + ' ' : ''}{\n`
    const label = name ? `${indent}label = ${genIdentifier(name)}\n` : ''
    const settings = `${indent}node [shape=none, margin=0]\n`
    return def + label + settings
}

function genFooter() {
    return '}\n'
}

function genEntity(e: Entity, relations: Relation[], gen: {doc: boolean}): string {
    const name = genEntityName(entityToRef(e))
    const attrs = (e.attrs || []).map(a => genAttribute(a, e, relations, gen))
    const rels = relations.map(r => genRelation(r, (e.attrs || []).find(a => attributePathSame(r.src.attrs[0], [a.name]))))
    const entityTable = [
        '<table border="0" cellborder="1" cellspacing="0" cellpadding="4">\n',
        `${indent}<tr><td bgcolor="lightblue" colspan="3">${name}</td></tr>\n`,
        ...attrs.map(a => indent + a),
        '</table>\n',
    ].map(line => indent + indent + line)
    return `${indent}${genIdentifier(name)} [label=<\n${entityTable.join('')}${indent}>]\n${rels.map(r => indent + r).join('')}`
}

function genAttribute(a: Attribute, e: Entity, relations: Relation[], gen: {doc: boolean}): string {
    const pk = e.pk && e.pk.attrs.some(attr => attributePathSame(attr, [a.name])) ? 'pk' : ''
    const attrRelations = relations.filter(r => r.src.attrs.some(attr => attributePathSame(attr, [a.name])))
    const fk = attrRelations.length > 0 ? 'fk' : ''
    const attrUniques = (e.indexes || []).filter(u => u.unique && u.attrs.some(attr => attributePathSame(attr, [a.name])))
    const uk = attrUniques.length > 0 ? 'unique' : ''
    const attrIndexes = (e.indexes || []).filter(u => !u.unique && u.attrs.some(attr => attributePathSame(attr, [a.name])))
    const idx = attrIndexes.length > 0 ? 'index' : ''
    const doc = gen.doc && a.doc ? `doc: ${a.doc}` : ''
    const attrs = [pk, fk, uk, idx, doc].filter(k => !!k).join(', ')
    return `<tr><td align="left">${a.name}</td><td align="left">${a.type}</td><td align="left">${attrs}</td></tr>\n`
}

function genRelation(r: Relation, a: Attribute | undefined): string {
    const label = r.src.attrs.length > 0 ? ` [label=${r.src.attrs.map(genAttributePath).join(',')}]` : ''
    return `${genIdentifier(genEntityName(r.src))} -> ${genIdentifier(genEntityName(r.ref))}${label}\n`
}

function genEntityName(e: EntityRef): string {
    if (e.database) return [e.database, e.catalog, e.schema, e.entity].map(v => v || '').join('.')
    if (e.catalog) return [e.catalog, e.schema, e.entity].map(v => v || '').join('.')
    if (e.schema) return [e.schema, e.entity].map(v => v || '').join('.')
    return e.entity
}

function genAttributePath(p: AttributePath): string {
    return p.join('.')
}

function genIdentifier(str: string): string {
    if (str.match(/^[a-zA-Z_][a-zA-Z0-9_-]*$/)) return str
    return '"' + str + '"'
}
