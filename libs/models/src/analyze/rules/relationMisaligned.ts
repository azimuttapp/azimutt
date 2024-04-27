import {isNotUndefined} from "@azimutt/utils";
import {AttributeRef, AttributeType, Entity, EntityId, EntityRef, Relation} from "../../database";
import {entityRefToId, getAttribute} from "../../databaseUtils";

/**
 * Relations are made to link entities by referencing a target record from a source record, mostly using the primary key.
 * As columns on both side of the relation store the same thing, they should also have the same type.
 * Sometimes, subtle differences (like varchar length) may not be an issue, it's far from ideal and may become one at some point.
 */

const missingEntityRuleId = 'relation-miss-entity'
const missingAttributeRuleId = 'relation-miss-attribute'
const misalignedTypeRuleId = 'relation-misaligned-type'

export type MisalignedType = {src: AttributeRef, srcType: AttributeType, ref: AttributeRef, refType: AttributeType}
export type RelationMisaligned = { relation: Relation, missingEntities: EntityRef[] }
    | { relation: Relation, missingAttrs: AttributeRef[] }
    | { relation: Relation, misalignedTypes: MisalignedType[] }

// same as frontend/src/PagesComponents/Organization_/Project_/Views/Modals/SchemaAnalysis/InconsistentTypeOnRelations.elm
export function getMisalignedRelation(relation: Relation, entities: Record<EntityId, Entity>): RelationMisaligned | undefined {
    const src = entities[entityRefToId(relation.src)]
    const ref = entities[entityRefToId(relation.ref)]
    const missingEntities: EntityRef[] = [src ? undefined : relation.src, ref ? undefined : relation.ref].filter(isNotUndefined)
    if (missingEntities.length > 0) {
        return {relation, missingEntities}
    }

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
    if (missingAttrs.length > 0) {
        return {relation, missingAttrs}
    }

    const misalignedTypes: MisalignedType[] = attrs.flatMap(attr => attr.srcAttr && attr.refAttr && attr.srcAttr.type !== attr.refAttr.type ? [{
        src: {...relation.src, attribute: attr.src},
        srcType: attr.srcAttr?.type,
        ref: {...relation.ref, attribute: attr.ref},
        refType: attr.refAttr?.type,
    }] : [])
    if (misalignedTypes.length > 0) {
        return {relation, misalignedTypes}
    }

    return undefined
}
