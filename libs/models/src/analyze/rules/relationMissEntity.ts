import {indexBy, isNotUndefined} from "@azimutt/utils";
import {Database, Entity, EntityId, EntityRef, Relation} from "../../database";
import {entityRefToId, entityToId, relationToId} from "../../databaseUtils";
import {Rule, RuleId, RuleLevel, RuleName, RuleViolation} from "../rule";

const ruleId: RuleId = 'relation-miss-entity'
const ruleName: RuleName = 'entity not found in relation'
const ruleLevel: RuleLevel = RuleLevel.enum.high
export const relationMissEntityRule: Rule = {
    id: ruleId,
    name: ruleName,
    level: ruleLevel,
    analyze(db: Database): RuleViolation[] {
        const entities: Record<EntityId, Entity> = indexBy(db.entities || [], entityToId)
        return (db.relations || []).map(r => getMissingEntityRelations(r, entities)).filter(isNotUndefined).map(violation => ({
            ruleId,
            ruleName,
            ruleLevel,
            entity: violation.relation.src,
            message: `Relation ${relationName(violation.relation)}, not found entities: ${violation.missingEntities.map(entityRefToId).join(', ')}`
        }))
    }
}

const relationName = (r: Relation): string => r.name || relationToId(r)

export type MissingEntityRelation = { relation: Relation, missingEntities: EntityRef[] }

export function getMissingEntityRelations(relation: Relation, entities: Record<EntityId, Entity>): MissingEntityRelation | undefined {
    const src = entities[entityRefToId(relation.src)]
    const ref = entities[entityRefToId(relation.ref)]
    const missingEntities: EntityRef[] = [src ? undefined : relation.src, ref ? undefined : relation.ref].filter(isNotUndefined)
    return missingEntities.length > 0 ? {relation, missingEntities} : undefined
}
