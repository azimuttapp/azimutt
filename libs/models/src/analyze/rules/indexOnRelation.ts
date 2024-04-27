import {isNotUndefined} from "@azimutt/utils";
import {AttributePath, Entity, EntityId, EntityRef, Relation} from "../../database";
import {attributePathToId, entityRefToId} from "../../databaseUtils";

/**
 * Relations are often used on JOIN or WHERE clauses to fetch more data or limit rows.
 * It can be a good practice to add indexes on most relation columns.
 */

export type MissingIndex = { ref: EntityRef, attrs: AttributePath[] }

// same as frontend/src/PagesComponents/Organization_/Project_/Views/Modals/SchemaAnalysis/IndexOnForeignKeys.elm
export function getMissingIndexOnRelation(relation: Relation, entities: Record<EntityId, Entity>): MissingIndex[] {
    return [
        hasIndex(relation.ref, relation.attrs.map(a => a.ref), entities),
        hasIndex(relation.src, relation.attrs.map(a => a.src), entities),
    ].filter(isNotUndefined)
}

function hasIndex(ref: EntityRef, attrs: AttributePath[], entities: Record<EntityId, Entity>): MissingIndex | undefined {
    const entity = entities[entityRefToId(ref)]
    if (!entity) return undefined // don't suggest new index if entity is not found
    if (matchIndex(entity.pk?.attrs || [], attrs) || entity.indexes?.find(i => matchIndex(i.attrs, attrs)) !== undefined) {
        return undefined
    } else {
        return {ref, attrs}
    }
}

function matchIndex(indexAttrs: AttributePath[], attributes: AttributePath[]): boolean {
    return attributes.every((a, i) => attributePathToId(a) === attributePathToId(indexAttrs[i] || []))
}
