import {z} from "zod";
import {indexBy, isNotUndefined} from "@azimutt/utils";
import {Timestamp} from "../../common";
import {AttributeRef, AttributesId, AttributeType, Database, Entity, EntityId, Relation} from "../../database";
import {
    attributeRefToId,
    attributesRefFromId,
    attributesRefSame,
    entityRefToId,
    entityToId,
    getAttribute,
    relationToId
} from "../../databaseUtils";
import {DatabaseQuery} from "../../interfaces/connector";
import {AnalyzeHistory, Rule, RuleConf, RuleId, RuleLevel, RuleName, RuleViolation} from "../rule";

/**
 * Relations are made to link entities by referencing a target record from a source record, mostly using the primary key.
 * As columns on both side of the relation store the same thing, they should also have the same type.
 * Sometimes, subtle differences (like varchar length) may not be an issue, it's far from ideal and may become one at some point.
 */

const ruleId: RuleId = 'relation-misaligned-type'
const ruleName: RuleName = 'misaligned relation'
const CustomRuleConf = RuleConf.extend({
    ignores: z.object({src: AttributesId, ref: AttributesId}).array().optional()
}).strict().describe('RelationMisalignedConf')
type CustomRuleConf = z.infer<typeof CustomRuleConf>
export const relationMisalignedRule: Rule<CustomRuleConf> = {
    id: ruleId,
    name: ruleName,
    conf: {level: RuleLevel.enum.high},
    zConf: CustomRuleConf,
    analyze(conf: CustomRuleConf, now: Timestamp, db: Database, queries: DatabaseQuery[], history: AnalyzeHistory[]): RuleViolation[] {
        const entities: Record<EntityId, Entity> = indexBy(db.entities || [], entityToId)
        const ignores = conf.ignores?.map(i => ({src: attributesRefFromId(i.src), ref: attributesRefFromId(i.ref)})) || []
        return (db.relations || [])
            .map(r => getMisalignedRelation(r, entities))
            .filter(isNotUndefined)
            .filter(v => !ignores.some(i => attributesRefSame(i.src, {...v.relation.src, attributes: v.relation.attrs.map(a => a.src)}) && attributesRefSame(i.ref, {...v.relation.ref, attributes: v.relation.attrs.map(a => a.ref)})))
            .map(violation => {
                const {extra, ...relation} = violation.relation
                return {
                    ruleId,
                    ruleName,
                    ruleLevel: conf.level,
                    message: `Relation ${relationName(violation.relation)} link attributes different types: ${violation.misalignedTypes.map(formatMisalignedType).join(', ')}`,
                    entity: violation.relation.src,
                    attribute: violation.relation.attrs[0].src,
                    extra: {relation, misalignedTypes: violation.misalignedTypes}
                }
            })
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
