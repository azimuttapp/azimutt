import {indexBy, isNotUndefined} from "@azimutt/utils";
import {AttributePath, Database, Entity, EntityId, EntityRef, Relation} from "../../database";
import {attributePathToId, entityAttributesToId, entityRefToId, entityToId, relationToId} from "../../databaseUtils";
import {Rule, RuleId, RuleLevel, RuleName, RuleViolation} from "../rule";

/**
 * Relations are often used on JOIN or WHERE clauses to fetch more data or limit rows.
 * It can be a good practice to add indexes on most relation columns.
 */

const ruleId: RuleId = 'index-on-relation'
const ruleName: RuleName = 'index on relation'
const ruleLevel: RuleLevel = RuleLevel.enum.medium
export const indexOnRelationRule: Rule = {
    id: ruleId,
    name: ruleName,
    level: ruleLevel,
    analyze(db: Database): RuleViolation[] {
        const entities: Record<EntityId, Entity> = indexBy(db.entities || [], entityToId)
        return (db.relations || []).flatMap(r => getMissingIndexOnRelation(r, entities)).map(i => ({
            ruleId,
            ruleName,
            ruleLevel,
            entity: i.ref,
            message: `Create an index on ${entityAttributesToId(i.ref, i.attrs)} to improve ${relationToId(i.relation)} relation.`
        }))
    }
}

export type MissingIndex = { relation: Relation, ref: EntityRef, attrs: AttributePath[] }

// same as frontend/src/PagesComponents/Organization_/Project_/Views/Modals/SchemaAnalysis/IndexOnForeignKeys.elm
export function getMissingIndexOnRelation(relation: Relation, entities: Record<EntityId, Entity>): MissingIndex[] {
    return [
        hasIndex(relation, relation.ref, relation.attrs.map(a => a.ref), entities),
        hasIndex(relation, relation.src, relation.attrs.map(a => a.src), entities),
    ].filter(isNotUndefined)
}

function hasIndex(relation: Relation, ref: EntityRef, attrs: AttributePath[], entities: Record<EntityId, Entity>): MissingIndex | undefined {
    const entity = entities[entityRefToId(ref)]
    if (!entity) return undefined // don't suggest new index if entity is not found
    if (matchIndex(entity.pk?.attrs || [], attrs) || entity.indexes?.find(i => matchIndex(i.attrs, attrs)) !== undefined) {
        return undefined
    } else {
        return {relation, ref, attrs}
    }
}

function matchIndex(indexAttrs: AttributePath[], attributes: AttributePath[]): boolean {
    return attributes.every((a, i) => attributePathToId(a) === attributePathToId(indexAttrs[i] || []))
}
