import {z} from "zod";
import {indexBy, isNotUndefined, zip} from "@azimutt/utils";
import {Timestamp} from "../../common";
import {
    AttributeRef,
    AttributeType,
    Database,
    Entity,
    EntityId,
    Relation,
    RelationId,
    RelationRef
} from "../../database";
import {
    attributeRefToId,
    entityRefToId,
    entityToId,
    getAttribute,
    relationLinkToEntityRef,
    relationRefFromId,
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

/**
 * Relations are made to link entities by referencing a target record from a source record, mostly using the primary key.
 * As columns on both side of the relation store the same thing, they should also have the same type.
 * Sometimes, subtle differences (like varchar length) may not be an issue, it's far from ideal and may become one at some point.
 */

const ruleId: RuleId = 'relation-misaligned-type'
const ruleName: RuleName = 'misaligned relation'
const ruleDescription: string = 'relations with different attribute type on each side'
const CustomRuleConf = RuleConf.extend({
    ignores: RelationId.array().optional()
}).strict().describe('RelationMisalignedConf')
type CustomRuleConf = z.infer<typeof CustomRuleConf>
export const relationMisalignedRule: Rule<CustomRuleConf> = {
    id: ruleId,
    name: ruleName,
    description: ruleDescription,
    conf: {level: RuleLevel.enum.high},
    zConf: CustomRuleConf,
    analyze(conf: CustomRuleConf, now: Timestamp, db: Database, queries: DatabaseQuery[], history: AnalyzeHistory[], reference: AnalyzeReportViolation[]): RuleViolation[] {
        const refIgnores: RelationRef[] = reference.map(r => r.extra?.relation ? relationToRef(r.extra?.relation) : undefined).filter(isNotUndefined)
        const ignores: RelationRef[] = refIgnores.concat(conf.ignores?.map(relationRefFromId) || [])
        const entities: Record<EntityId, Entity> = indexBy(db.entities || [], entityToId)
        return (db.relations || [])
            .map(r => getMisalignedRelation(r, entities))
            .filter(isNotUndefined)
            .filter(v => !ignores.some(i => relationRefSame(i, relationToRef(v.relation))))
            .map(violation => {
                const {extra, ...relation} = violation.relation
                return {
                    ruleId,
                    ruleName,
                    ruleLevel: conf.level,
                    message: `Relation ${relationName(violation.relation)} link attributes different types: ${violation.misalignedTypes.map(formatMisalignedType).join(', ')}`,
                    entity: relationLinkToEntityRef(violation.relation.src),
                    attribute: violation.relation.src.attrs[0],
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

    const attrs = zip(relation.src.attrs, relation.ref.attrs).map(([srcAttr, refAttr]) => ({
        src: srcAttr,
        srcAttr: getAttribute(src.attrs, srcAttr),
        ref: refAttr,
        refAttr: getAttribute(ref.attrs, refAttr),
    }))
    if (attrs.some(a => !a.srcAttr || !a.refAttr)) { return undefined }

    const misalignedTypes: MisalignedType[] = attrs.flatMap(attr => attr.srcAttr && attr.refAttr && attr.srcAttr.type !== attr.refAttr.type ? [{
        src: {...relationLinkToEntityRef(relation.src), attribute: attr.src},
        srcType: attr.srcAttr?.type,
        ref: {...relationLinkToEntityRef(relation.ref), attribute: attr.ref},
        refType: attr.refAttr?.type,
    }] : [])
    return misalignedTypes.length > 0 ? {relation, misalignedTypes} : undefined
}
