import {z} from "zod";
import {indexBy, isNotUndefined} from "@azimutt/utils";
import {Timestamp} from "../../common";
import {
    AttributePath,
    AttributesId,
    AttributesRef,
    Database,
    Entity,
    EntityId,
    Relation,
    RelationLink
} from "../../database";
import {
    attributePathToId,
    attributesRefFromId,
    attributesRefSame,
    attributesRefToId,
    entityRefToId,
    entityToId,
    relationLinkToEntityRef,
    relationToId
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
 * Relations are often used on JOIN or WHERE clauses to fetch more data or limit rows.
 * It can be a good practice to add indexes on most relation columns.
 */

const ruleId: RuleId = 'index-on-relation'
const ruleName: RuleName = 'index on relation'
const ruleDescription: string = 'relation attributes with no index'
const CustomRuleConf = RuleConf.extend({
    ignores: AttributesId.array().optional()
}).strict().describe('IndexOnRelationConf')
type CustomRuleConf = z.infer<typeof CustomRuleConf>
export const indexOnRelationRule: Rule<CustomRuleConf> = {
    id: ruleId,
    name: ruleName,
    description: ruleDescription,
    conf: {level: RuleLevel.enum.medium},
    zConf: CustomRuleConf,
    analyze(conf: CustomRuleConf, now: Timestamp, db: Database, queries: DatabaseQuery[], history: AnalyzeHistory[], reference: AnalyzeReportViolation[]): RuleViolation[] {
        const refIgnores: AttributesRef[] = reference.map(r => r.entity && Array.isArray(r.extra?.indexAttrs) ? {...r.entity, attrs: r.extra.indexAttrs} : undefined).filter(isNotUndefined)
        const ignores: AttributesRef[] = refIgnores.concat(conf.ignores?.map(attributesRefFromId) || [])
        const entities: Record<EntityId, Entity> = indexBy(db.entities || [], entityToId)
        return (db.relations || [])
            .flatMap(r => getMissingIndexOnRelation(r, entities))
            .filter(idx => !ignores.some(i => attributesRefSame(i, {...idx.ref, attrs: idx.ref.attrs})))
            .map(i => ({
                ruleId,
                ruleName,
                ruleLevel: conf.level,
                message: `Create an index on ${attributesRefToId({...i.ref, attrs: i.ref.attrs})} to improve ${relationToId(i.relation)} relation.`,
                entity: relationLinkToEntityRef(i.ref),
                attribute: i.ref.attrs[0],
                extra: {indexAttrs: i.ref.attrs, relation: i.relation}
            }))
    }
}

export type MissingIndex = { relation: Relation, ref: RelationLink }

// same as frontend/src/PagesComponents/Organization_/Project_/Views/Modals/SchemaAnalysis/IndexOnForeignKeys.elm
export function getMissingIndexOnRelation(relation: Relation, entities: Record<EntityId, Entity>): MissingIndex[] {
    return [
        hasIndex(relation, relation.ref, entities),
        hasIndex(relation, relation.src, entities),
    ].filter(isNotUndefined)
}

function hasIndex(relation: Relation, ref: RelationLink, entities: Record<EntityId, Entity>): MissingIndex | undefined {
    const entity = entities[entityRefToId(ref)]
    if (!entity) return undefined // don't suggest new index if entity is not found
    if (matchIndex(entity.pk?.attrs || [], ref.attrs) || entity.indexes?.find(i => matchIndex(i.attrs, ref.attrs)) !== undefined) {
        return undefined
    } else {
        return {relation, ref}
    }
}

function matchIndex(indexAttrs: AttributePath[], attributes: AttributePath[]): boolean {
    return attributes.every((a, i) => attributePathToId(a) === attributePathToId(indexAttrs[i] || []))
}
