import {ZodError, ZodType} from "zod";
import {errorToString, groupBy, partition} from "@azimutt/utils";
import {Attribute, Database, Entity, Relation} from "../database";
import {attributePathToId, entityRefToId, entityToId} from "../databaseUtils";
import {zodErrorToString} from "../zod";

export function dbToPrompt(db: Database): string {
    // TODO: depending on selected model, decide if db can be fully integrated or should be compressed (no types, filter tables...) or have additional data (sample values, stats...)
    const relationsBySrc = groupBy(db.relations || [], r => entityRefToId(r.src))
    const entities = (db.entities || []).map(e => entityToPrompt(e, relationsBySrc[entityToId(e)] || []))
    return `\`\`\`
${entities.join('\n')}
\`\`\``
}

export function entityToPrompt(e: Entity, rels: Relation[]): string {
    const [compositeRelations, simpleRelations] = partition(rels, r => r.src.attrs.length > 1)
    const simpleRelationsByAttr = groupBy(simpleRelations, r => attributePathToId(r.src.attrs[0]))
    const polymorphicRelations = Object.values(simpleRelationsByAttr).filter(rs => rs.length > 1).flatMap(rs => rs)
    const attrs = (e.attrs || []).map(a => attributeToPrompt(a, simpleRelationsByAttr[a.name] || []))
    const otherRels = compositeRelations.concat(polymorphicRelations).map(entityForeignKey)
    return `CREATE TABLE ${entityToId(e)} (${attrs.concat(otherRels).join(', ')});`
}

function attributeToPrompt(a: Attribute, rels: Relation[]): string {
    return `${a.name} ${a.type}${rels.length === 1 ? ` REFERENCES ${entityRefToId(rels[0].ref)}(${attributePathToId(rels[0].ref.attrs[0])})` : ''}`
}

function entityForeignKey(r: Relation): string {
    return `FOREIGN KEY (${r.src.attrs.map(attributePathToId).join(', ')}) REFERENCES ${entityRefToId(r.ref)}(${r.ref.attrs.map(attributePathToId).join(', ')})`
}

export function cleanSqlAnswer(answer: string): string {
    const mdCode = answer.trim().match(/^(?:```)?(?:sql)?\n?(.+?)\n?(?:```)?$/s)
    if (mdCode) return mdCode[1]
    return answer.trim()
}

export function cleanJsonAnswer<T>(answer: string, type: ZodType<T>): Promise<T> {
    const mdCode = answer.trim().match(/^(?:```)?(?:json)?\n?(.+?)\n?(?:```)?$/s)
    const json = mdCode ? mdCode[1].trim() : answer.trim()
    try {
        return Promise.resolve(type.parse(JSON.parse(json)))
    } catch (e) {
        if (e instanceof SyntaxError) return Promise.reject('Invalid JSON: ' + answer)
        if (e instanceof ZodError) return Promise.reject(zodErrorToString(e, type, undefined, JSON.parse(json)).replace('ZodType,', 'format'))
        return Promise.reject('Invalid LLM JSON: ' + errorToString(e))
    }
}
