import {groupBy, partition} from "@azimutt/utils";
import {Attribute, Database, Entity, Relation} from "../database";
import {attributePathToId, entityRefToId, entityToId} from "../databaseUtils";

export function dbToPrompt(db: Database): string {
    // TODO: depending on selected model, decide if db can be fully integrated or should be compressed (no types, filter tables...) or have additional data (sample values, stats...)
    const relationsBySrc = groupBy(db.relations || [], r => entityRefToId(r.src))
    const entities = (db.entities || []).map(e => entityToPrompt(e, relationsBySrc[entityToId(e)] || []))
    return `\`\`\`
${entities.join('\n')}
\`\`\``
}

export function entityToPrompt(e: Entity, rels: Relation[]): string {
    const [compositeRelations, simpleRelations] = partition(rels, r => r.attrs.length > 1)
    const simpleRelationsByAttr = groupBy(simpleRelations, r => attributePathToId(r.attrs[0].src))
    const polymorphicRelations = Object.values(simpleRelationsByAttr).filter(rs => rs.length > 1).flatMap(rs => rs)
    const attrs = e.attrs.map(a => attributeToPrompt(a, simpleRelationsByAttr[a.name] || []))
    const otherRels = compositeRelations.concat(polymorphicRelations).map(entityForeignKey)
    return `CREATE TABLE ${entityToId(e)} (${attrs.concat(otherRels).join(', ')});`
}

function attributeToPrompt(a: Attribute, rels: Relation[]): string {
    return `${a.name} ${a.type}${rels.length === 1 ? ` REFERENCES ${entityRefToId(rels[0].ref)}(${attributePathToId(rels[0].attrs[0].ref)})` : ''}`
}

function entityForeignKey(r: Relation): string {
    return `FOREIGN KEY (${r.attrs.map(a => attributePathToId(a.src)).join(', ')}) REFERENCES ${entityRefToId(r.ref)}(${r.attrs.map(a => attributePathToId(a.ref)).join(', ')})`
}

export function cleanSqlAnswer(answer: string): string {
    const mdCode = answer.trim().match(/^(?:```)?(?:sql)?\n?(.+)\n?(?:```)?$/)
    if (mdCode) return mdCode[1]
    return answer.trim()
}
