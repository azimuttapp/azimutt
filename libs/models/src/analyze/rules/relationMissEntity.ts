import {z} from "zod";
import {indexBy, isNotUndefined} from "@azimutt/utils";
import {Timestamp} from "../../common";
import {Database, Entity, EntityId, EntityRef, Relation, RelationRef} from "../../database";
import {
    entityRefFromId,
    entityRefSame,
    entityRefToId,
    entityToId,
    relationLinkToEntityRef,
    relationRefSame,
    relationToId,
    relationToRef
} from "../../databaseUtils";
import {DatabaseQuery} from "../../interfaces/connector";
import {
    AnalyzeHistory,
    AnalyzeReportViolation,
    Rule,
    RuleConf,
    RuleId,
    RuleLevel,
    RuleName,
    RuleViolation
} from "../rule";

const ruleId: RuleId = 'relation-miss-entity'
const ruleName: RuleName = 'entity not found in relation'
const ruleDescription: string = 'relations with an entity not found in the database'
const CustomRuleConf = RuleConf.extend({
    ignores: EntityId.array().optional(),
}).strict().describe('RelationMissEntityConf')
type CustomRuleConf = z.infer<typeof CustomRuleConf>
export const relationMissEntityRule: Rule<CustomRuleConf> = {
    id: ruleId,
    name: ruleName,
    description: ruleDescription,
    conf: {level: RuleLevel.enum.high},
    zConf: CustomRuleConf,
    analyze(conf: CustomRuleConf, now: Timestamp, db: Database, queries: DatabaseQuery[], history: AnalyzeHistory[], reference: AnalyzeReportViolation[]): RuleViolation[] {
        const relIgnores: RelationRef[] = reference.map(r => r.extra?.relation ? relationToRef(r.extra?.relation) : undefined).filter(isNotUndefined)
        const entIgnores: EntityRef[] = conf.ignores?.map(entityRefFromId) || []
        const entities: Record<EntityId, Entity> = indexBy(db.entities || [], entityToId)
        return (db.relations || [])
            .map(r => getMissingEntityRelations(r, entities))
            .filter(isNotUndefined)
            .filter(v => !relIgnores.some(i => relationRefSame(i, relationToRef(v.relation))))
            .map(v => ({...v, missingEntities: v?.missing?.filter(e => !entIgnores.some(i => entityRefSame(i, e)))}))
            .filter(v => v.missingEntities.length > 0)
            .map(violation => ({
                ruleId,
                ruleName,
                ruleLevel: conf.level,
                message: `Relation ${relationName(violation.relation)}, not found entities: ${violation.missingEntities.map(entityRefToId).join(', ')}`,
                entity: violation.missingEntities[0],
                extra: violation
            }))
    }
}

const relationName = (r: Relation): string => r.name || relationToId(r)

export type MissingEntityRelation = { relation: Relation, missing: EntityRef[] }

export function getMissingEntityRelations(relation: Relation, entities: Record<EntityId, Entity>): MissingEntityRelation | undefined {
    const src = entities[entityRefToId(relation.src)]
    const ref = entities[entityRefToId(relation.ref)]
    const missing: EntityRef[] = [src ? undefined : relationLinkToEntityRef(relation.src), ref ? undefined : relationLinkToEntityRef(relation.ref)].filter(isNotUndefined)
    return missing.length > 0 ? {relation, missing} : undefined
}
