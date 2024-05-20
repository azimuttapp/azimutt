import {z} from "zod";
import {indexBy, isNotUndefined} from "@azimutt/utils";
import {Database, Entity, EntityId, EntityRef, Relation} from "../../database";
import {entityRefFromId, entityRefSame, entityRefToId, entityToId, relationToId} from "../../databaseUtils";
import {DatabaseQuery} from "../../interfaces/connector";
import {Rule, RuleConf, RuleId, RuleLevel, RuleName, RuleViolation} from "../rule";

const ruleId: RuleId = 'relation-miss-entity'
const ruleName: RuleName = 'entity not found in relation'
const CustomRuleConf = RuleConf.extend({
    ignores: EntityId.array().optional(),
}).strict().describe('RelationMissEntityConf')
type CustomRuleConf = z.infer<typeof CustomRuleConf>
export const relationMissEntityRule: Rule<CustomRuleConf> = {
    id: ruleId,
    name: ruleName,
    conf: {level: RuleLevel.enum.high},
    zConf: CustomRuleConf,
    analyze(conf: CustomRuleConf, db: Database, queries: DatabaseQuery[]): RuleViolation[] {
        const entities: Record<EntityId, Entity> = indexBy(db.entities || [], entityToId)
        const ignores: EntityRef[] = conf.ignores?.map(entityRefFromId) || []
        return (db.relations || [])
            .map(r => getMissingEntityRelations(r, entities))
            .filter(isNotUndefined)
            .map(v => ({...v, missingEntities: v?.missingEntities?.filter(e => !ignores.some(i => entityRefSame(i, e)))}))
            .filter(v => v.missingEntities.length > 0)
            .map(violation => ({
                ruleId,
                ruleName,
                ruleLevel: conf.level,
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
