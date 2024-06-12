import {z} from "zod";
import {indexBy, isNotUndefined} from "@azimutt/utils";
import {Timestamp} from "../../common";
import {AttributeId, AttributeRef, Database, Entity, EntityId, Relation, RelationRef} from "../../database";
import {
    attributeRefFromId,
    attributeRefSame,
    attributeRefToId,
    entityRefToId,
    entityToId,
    getAttribute,
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

const ruleId: RuleId = 'relation-miss-attribute'
const ruleName: RuleName = 'attribute not found in relation'
const CustomRuleConf = RuleConf.extend({
    ignores: AttributeId.array().optional(),
}).strict().describe('RelationMissAttributeConf')
type CustomRuleConf = z.infer<typeof CustomRuleConf>
export const relationMissAttributeRule: Rule<CustomRuleConf> = {
    id: ruleId,
    name: ruleName,
    conf: {level: RuleLevel.enum.high},
    zConf: CustomRuleConf,
    analyze(conf: CustomRuleConf, now: Timestamp, db: Database, queries: DatabaseQuery[], history: AnalyzeHistory[], reference: AnalyzeReportViolation[]): RuleViolation[] {
        const relIgnores: RelationRef[] = reference.map(r => r.extra?.relation ? relationToRef(r.extra?.relation) : undefined).filter(isNotUndefined)
        const attrIgnores: AttributeRef[] = conf.ignores?.map(attributeRefFromId) || []
        const entities: Record<EntityId, Entity> = indexBy(db.entities || [], entityToId)
        return (db.relations || [])
            .map(r => getMissingAttributeRelations(r, entities))
            .filter(isNotUndefined)
            .filter(v => !relIgnores.some(i => relationRefSame(i, relationToRef(v.relation))))
            .map(v => ({...v, missingAttrs: v?.missing?.filter(a => !attrIgnores.some(i => attributeRefSame(i, a)))}))
            .filter(v => v.missingAttrs.length > 0)
            .map(violation => {
                const {attribute, ...entity} = violation.missingAttrs[0]
                return {
                    ruleId,
                    ruleName,
                    ruleLevel: conf.level,
                    message: `Relation ${relationName(violation.relation)}, not found attributes: ${violation.missingAttrs.map(attributeRefToId).join(', ')}`,
                    entity,
                    attribute,
                    extra: violation
                }
            })
    }
}

const relationName = (r: Relation): string => r.name || relationToId(r)

export type MissingAttributeRelation = { relation: Relation, missing: AttributeRef[] }

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
    const missing: AttributeRef[] = attrs.flatMap(attr => [
        attr.srcAttr ? undefined : {...relation.src, attribute: attr.src},
        attr.refAttr ? undefined : {...relation.ref, attribute: attr.ref},
    ].filter(isNotUndefined))
    return missing.length > 0 ? {relation, missing} : undefined
}
