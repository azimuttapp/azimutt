import {indexBy, isNotUndefined} from "@azimutt/utils";
import {AttributeRef, Database, Entity, EntityId, Relation} from "../../database";
import {attributeRefToId, entityRefToId, entityToId, getAttribute, relationToId} from "../../databaseUtils";
import {Rule, RuleId, RuleLevel, RuleName, RuleViolation} from "../rule";

const ruleId: RuleId = 'relation-miss-attribute'
const ruleName: RuleName = 'attribute not found in relation'
const ruleLevel: RuleLevel = RuleLevel.enum.high
export const relationMissAttributeRule: Rule = {
    id: ruleId,
    name: ruleName,
    level: ruleLevel,
    analyze(db: Database): RuleViolation[] {
        const entities: Record<EntityId, Entity> = indexBy(db.entities || [], entityToId)
        return (db.relations || []).map(r => getMissingAttributeRelations(r, entities)).filter(isNotUndefined).map(violation => ({
            ruleId,
            ruleName,
            ruleLevel,
            entity: violation.relation.src,
            message: `Relation ${relationName(violation.relation)}, not found attributes: ${violation.missingAttrs.map(attributeRefToId).join(', ')}`
        }))
    }
}

const relationName = (r: Relation): string => r.name || relationToId(r)

export type MissingAttributeRelation = { relation: Relation, missingAttrs: AttributeRef[] }

export function getMissingAttributeRelations(relation: Relation, entities: Record<EntityId, Entity>): MissingAttributeRelation | undefined {
    const src = entities[entityRefToId(relation.src)]
    const ref = entities[entityRefToId(relation.ref)]
    if (!src || !ref) { return undefined }

    const attrs = relation.attrs.map(attr => ({
        src: attr.src,
        srcAttr: getAttribute(src.attrs, attr.src),
        ref: attr.ref,
        refAttr: getAttribute(ref.attrs, attr.ref),
    }))
    const missingAttrs: AttributeRef[] = attrs.flatMap(attr => [
        attr.srcAttr ? undefined : {...relation.src, attribute: attr.src},
        attr.refAttr ? undefined : {...relation.ref, attribute: attr.ref},
    ].filter(isNotUndefined))
    return missingAttrs.length > 0 ? {relation, missingAttrs} : undefined
}
