import {joinLast, slugifyGitHub} from "@azimutt/utils";
import {
    Attribute,
    AttributePath,
    attributePathSame,
    AttributeValue,
    Database,
    Entity,
    EntityRef,
    entityRefSame,
    entityToRef,
    Namespace,
    Relation,
    Type
} from "@azimutt/models";
import {generateMermaid} from "./mermaidGenerator";

export function generateMarkdown(database: Database): string {
    return genTitle(database) + genSummary(database) + genEntities(database) + genTypes(database) + genDiagram(database)
}

const titleEntities = 'Entities'
const titleTypes = 'Types'
const titleDiagram = 'Diagram'

function genTitle(db: Database): string {
    return `# ${db.stats?.name || 'Database documentation by Azimutt'}\n\n`
}

function genSummary(db: Database): string {
    const entities = (db.entities || []).map(genName).map(name => `  - ${mdAnchor(name)}\n`).join('')
    const types = (db.types || []).map(genName).map(name => `  - ${mdAnchor(name)}\n`).join('')
    return '## Summary\n\n' +
        (`- ${mdAnchor(titleEntities)}\n` + entities) +
        (`- ${mdAnchor(titleTypes)}\n` + types) +
        `- ${mdAnchor(titleDiagram)}\n\n`
}

function genEntities(db: Database): string {
    const entities = (db.entities || []).map(e => {
        const ref = entityToRef(e)
        const entityRelations = (db.relations || []).filter(r => entityRefSame(r.src, ref))
        return genEntity(e, entityRelations)
    }).join('')
    return `## ${titleEntities}\n\n${entities || 'No defined entities\n\n'}`
}

function genEntity(e: Entity, relations: Relation[]): string {
    const doc = e.doc ? `${e.doc}\n\n` : ''
    const def = e.def ? `View definition:\n\`\`\`sql\n${e.def.trim()}\n\`\`\`\n\n` : ''
    const attrs = (e.attrs || []).map(a => genAttribute(a, e, relations))
    const attrTable = attrs.length > 0 ? mdTable(attrs.map(a => ['**' + a.attr + '**', a.type, a.props, a.ref, a.doc]), ['Attribute', 'Type', 'Properties', 'Reference', 'Documentation']) + '\n' : ''
    const compositeIndexes = (e.indexes || []).filter(i => i.attrs.length > 1).map(i => `- ${i.unique ? 'unique ' : ''}index on (${i.attrs.map(genAttributePath).join(', ')})${i.name ? `: ${i.name}` : ''}\n`)
    const compositeChecks = (e.checks || []).filter(c => c.attrs.length > 1).map(i => `- check(${i.predicate})${i.name ? `: ${i.name}` : ''}\n`)
    const compositeRelations = relations.filter(r => r.attrs.length > 1).map(r => `- relation: ${genEntityRef(r.src)}(${r.attrs.map(a => genAttributePath(a.src)).join(', ')}) -> ${genEntityRef(r.ref)}(${r.attrs.map(a => genAttributePath(a.ref)).join(', ')})\n`)
    const constraints = compositeIndexes.concat(compositeChecks, compositeRelations)
    return `### ${genName(e)}\n\n${doc}${def}${attrTable}${constraints.length > 0 ? `Constraints:\n\n${constraints.join('')}\n` : ''}`
}

type AttributeRow = {attr: string, type: string, props: string, ref: string, doc: string}

// TODO: nested attributes
function genAttribute(a: Attribute, e: Entity, relations: Relation[]): AttributeRow {
    const pk = e.pk && e.pk.attrs.length === 1 && attributePathSame(e.pk.attrs[0], [a.name]) ? 'PK' : ''
    const attrUniques = (e.indexes || []).filter(u => u.unique && u.attrs.length === 1 && attributePathSame(u.attrs[0], [a.name]))
    const unique = attrUniques.length === 1 ? 'unique' : ''
    const attrIndexes = (e.indexes || []).filter(u => !u.unique && u.attrs.length === 1 && attributePathSame(u.attrs[0], [a.name]))
    const index = attrIndexes.length === 1 ? 'index' : ''
    const checks = (e.checks || []).filter(c => c.attrs.length === 1 && attributePathSame(c.attrs[0], [a.name])).map(c => c.predicate ? `check(${c.predicate})` : 'check')
    const notNull = a.null ? 'nullable' : ''
    const props = [pk, unique, index, ...checks, notNull].filter(k => !!k).join(', ')
    const attrRelations = relations.filter(r => r.attrs.length === 1 && attributePathSame(r.attrs[0].src, [a.name]))
    const ref = attrRelations.length > 0 ? joinLast(attrRelations.map(r => `${genEntityRef(r.ref)}.${genAttributePath(r.attrs[0].ref)}${r.polymorphic ? ` (${genAttributePath(r.polymorphic.attribute)}=${genAttributeValue(r.polymorphic.value)})` : ''}`), ', ', ' or ') : ''
    return {attr: a.name, type: a.type, props, ref, doc: a.doc?.replaceAll(/\n/g, '\\n') || ''}
}

function genTypes(db: Database): string {
    const types = (db.types || []).map(genType).join('')
    return `## ${titleTypes}\n\n${types || 'No custom types\n\n'}`
}

function genType(t: Type): string {
    const doc = t.doc ? `${t.doc}\n\n` : ''
    return `### ${genName(t)}\n\n${doc}${genTypeContent(t)}\n\n`
}

function genTypeContent(t: Type): string {
    if (t.alias) return 'ALIAS: ' + t.alias
    if (t.values) return 'ENUM: ' + t.values.join(', ')
    if (t.attrs) return 'STRUCT:' + t.attrs.map(a => `\n  ${a.name} ${a.type}`).join('')
    if (t.definition) return 'EXPRESSION: ' + t.definition
    return 'UNKNOWN'
}

function genDiagram(db: Database): string {
    return `## ${titleDiagram}

\`\`\`mermaid
${generateMermaid(db).trim()}
\`\`\`
`
}

function genEntityRef(e: EntityRef) {
    return genName({...e, name: e.entity})
}

function genName(e: Namespace & { name: string }): string {
    if (e.database) return [e.database, e.catalog, e.schema, e.name].map(v => v || '').join('.')
    if (e.catalog) return [e.catalog, e.schema, e.name].map(v => v || '').join('.')
    if (e.schema) return [e.schema, e.name].map(v => v || '').join('.')
    return e.name
}

function genAttributePath(p: AttributePath): string {
    return p.join('.')
}

function genAttributeValue(v: AttributeValue): string {
    if (v === undefined) return ''
    if (v === null) return 'null'
    if (typeof v === 'string') return v.startsWith('`') ? v.slice(1, -1) : v
    if (typeof v === 'number') return v.toString()
    if (typeof v === 'boolean') return v ? 'true' : 'false'
    return `${v}`
}

function mdAnchor(value: string): string {
    return `[${value}](#${slugifyGitHub(value)})`
}

function mdTable(rows: string[][], headers: string[]): string {
    const width: number[] = headers.map((h, i) => Math.max(h.length, ...rows.map(row => row[i].length)))
    return (headers.map((h, i) => `| ${h.padEnd(width[i], ' ')} `).join('') + '|\n') +
        (headers.map((h, i) => `|-${''.padEnd(width[i], '-')}-`).join('') + '|\n') +
        (rows.map(row => row.map((value, i) => `| ${value.padEnd(width[i], ' ')} `).join('') + '|\n').join(''))
}
