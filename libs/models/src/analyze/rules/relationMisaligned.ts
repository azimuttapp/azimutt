import {indexBy, isNotUndefined} from "@azimutt/utils";
import {AttributeRef, AttributeType, Database, Entity, EntityId, Relation} from "../../database";
import {attributeRefToId, entityRefToId, entityToId, getAttribute, relationToId} from "../../databaseUtils";
import {Rule, RuleId, RuleLevel, RuleName, RuleViolation} from "../rule";

/**
 * Relations are made to link entities by referencing a target record from a source record, mostly using the primary key.
 * As columns on both side of the relation store the same thing, they should also have the same type.
 * Sometimes, subtle differences (like varchar length) may not be an issue, it's far from ideal and may become one at some point.
 */

const ruleId: RuleId = 'relation-misaligned-type'
const ruleName: RuleName = 'misaligned relation'
const ruleLevel: RuleLevel = RuleLevel.enum.high
export const relationMisalignedRule: Rule = {
    id: ruleId,
    name: ruleName,
    level: ruleLevel,
    analyze(db: Database): RuleViolation[] {
        const entities: Record<EntityId, Entity> = indexBy(db.entities || [], entityToId)
        return (db.relations || []).map(r => getMisalignedRelation(r, entities)).filter(isNotUndefined).map(violation => ({
            ruleId,
            ruleName,
            ruleLevel,
            entity: violation.relation.src,
            message: `Relation ${relationName(violation.relation)} link attributes different types: ${violation.misalignedTypes.map(formatMisalignedType).join(', ')}`
        }))
    }
}

const relationName = (r: Relation): string => r.name || relationToId(r)
const formatMisalignedType = (t: MisalignedType): string => `${attributeRefToId(t.src)}: ${t.srcType} != ${attributeRefToId(t.ref)}: ${t.refType}`

export type MisalignedType = {src: AttributeRef, srcType: AttributeType, ref: AttributeRef, refType: AttributeType}
export type RelationMisaligned = { relation: Relation, misalignedTypes: MisalignedType[] }

// same as frontend/src/PagesComponents/Organization_/Project_/Views/Modals/SchemaAnalysis/InconsistentTypeOnRelations.elm
export function getMisalignedRelation(relation: Relation, entities: Record<EntityId, Entity>): RelationMisaligned | undefined {
    const src = entities[entityRefToId(relation.src)]
    const ref = entities[entityRefToId(relation.ref)]
    if (!src && !ref) { return undefined }

    const attrs = relation.attrs.map(attr => ({
        src: attr.src,
        srcAttr: getAttribute(src.attrs, attr.src),
        ref: attr.ref,
        refAttr: getAttribute(ref.attrs, attr.ref),
    }))
    if (attrs.some(a => !a.srcAttr || !a.refAttr)) { return undefined }

    const misalignedTypes: MisalignedType[] = attrs.flatMap(attr => attr.srcAttr && attr.refAttr && attr.srcAttr.type !== attr.refAttr.type ? [{
        src: {...relation.src, attribute: attr.src},
        srcType: attr.srcAttr?.type,
        ref: {...relation.ref, attribute: attr.ref},
        refType: attr.refAttr?.type,
    }] : [])
    return misalignedTypes.length > 0 ? {relation, misalignedTypes} : undefined
}
