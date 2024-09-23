import {isNever} from "@azimutt/utils";
import {
    Attribute,
    AttributePath,
    attributePathSame,
    Database,
    Entity,
    EntityRef,
    entityRefSame,
    entityToRef,
    Relation,
    RelationKind
} from "@azimutt/models";

// see https://mermaid.js.org/syntax/entityRelationshipDiagram.html
export function generateMermaid(database: Database): string {
    const entities = (database.entities || []).map(e => {
        const ref = entityToRef(e)
        const entityRelations = (database.relations || []).filter(r => entityRefSame(r.src, ref))
        return genEntity(e, entityRelations)
    }).join('\n')
    return genTitle(database) + 'erDiagram\n' + entities
}

const indent = '    '

function genTitle(db: Database): string {
    return db.stats?.name ? `---\ntitle: ${db.stats.name}\n---\n` : ''
}

// TODO: handle alias
function genEntity(e: Entity, relations: Relation[]): string {
    const attrs = (e.attrs || []).map(a => genAttribute(a, e, relations)).join('')
    const rels = relations.map(r => genRelation(r, (e.attrs || []).find(a => attributePathSame(r.attrs[0].src, [a.name])))).join('')
    return `${indent}${genEntityName(entityToRef(e))}${attrs ? ` {\n${attrs}${indent}}` : ''}\n${rels}`
}

function genAttribute(a: Attribute, e: Entity, relations: Relation[]): string {
    const pk = e.pk && e.pk.attrs.length === 1 && attributePathSame(e.pk.attrs[0], [a.name]) ? 'PK' : ''
    const attrRelations = relations.filter(r => r.attrs.length === 1 && attributePathSame(r.attrs[0].src, [a.name]))
    const fk = attrRelations.length > 0 ? 'FK' : ''
    const attrUniques = (e.indexes || []).filter(u => u.unique && u.attrs.length === 1 && attributePathSame(u.attrs[0], [a.name]))
    const uk = attrUniques.length === 1 ? 'UK' : ''
    const keys = [pk, fk, uk].filter(k => !!k).join(', ')
    return `${indent}${indent}${genType(a.type)} ${genType(a.name)}${keys ? ' ' + keys : ''}${a.doc ? ` "${a.doc.replaceAll(/"/g, '')}"` : ''}\n`
}

function genRelation(r: Relation, a: Attribute | undefined): string {
    const name = r.name ? genIdentifier(r.name) : r.doc ? genIdentifier(r.doc) : r.attrs && r.attrs[0] ? genAttributePath(r.attrs[0].src) : '""'
    return `${indent}${genEntityName(r.src)} ${genRelationKind(r.kind, a)} ${genEntityName(r.ref)} : ${name}\n`
}

function genRelationKind(k: RelationKind | undefined, a: Attribute | undefined): string {
    const inner = a?.null ? '..' : '--'
    if (k === undefined || k === 'many-to-one') return `}o${inner}||`
    if (k === 'one-to-many') return `||${inner}o{`
    if (k === 'one-to-one') return `||${inner}||`
    if (k === 'many-to-many') return `}o${inner}o{`
    return isNever(k)
}

function genEntityName(e: EntityRef): string {
    const database = e.database ? genIdentifier(e.database) + '.' : ''
    const catalog = e.catalog ? genIdentifier(e.catalog) + '.' : ''
    const schema = e.schema ? genIdentifier(e.schema) + '.' : ''
    return genIdentifier(database + catalog + schema + e.entity)
}

function genAttributePath(p: AttributePath): string {
    return genIdentifier(p.join('.'))
}

function genIdentifier(str: string): string {
    if (str.match(/[a-zA-Z_][a-zA-Z0-9_-]*/)) return str
    return '"' + str + '"'
}

function genType(str: string): string {
    if (str.match(/[a-zA-Z][a-zA-Z0-9()\[\]_-]*/)) return str
    return '"' + str + '"'
}
