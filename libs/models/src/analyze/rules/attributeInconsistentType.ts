import {filterValues, groupBy} from "@azimutt/utils";
import {Attribute, AttributeName, AttributeRef, Entity} from "../../database";
import {entityToRef, flattenAttribute} from "../../databaseUtils";

/**
 * There is nothing wrong with inconsistent types on columns with identical name.
 * But sometimes, it's a hint of a same value or concept stored with a different format and may cause issues or misunderstandings.
 * Of course, not every column with the same name stores the exact same thing, and it may be totally fine.
 * Just have a look to be aware, and fix what need to be fixed.
 */

export type AttributeWithRef = { ref: AttributeRef, value: Attribute }

// same as frontend/src/PagesComponents/Organization_/Project_/Views/Modals/SchemaAnalysis/InconsistentTypeOnColumns.elm
export function getInconsistentAttributeTypes(entities: Entity[]): Record<AttributeName, AttributeWithRef[]> {
    const attributes: AttributeWithRef[] = entities.flatMap(e => e.attrs.flatMap(a => flattenAttribute(a)).map(a => ({
        ref: {...entityToRef(e), attribute: a.path},
        value: a.attr
    })))
    const attributesByName: Record<AttributeName, AttributeWithRef[]> = groupBy(attributes, a => a.value.name)
    return filterValues(attributesByName, (attrs: AttributeWithRef[]) => !attrs.every(a => a.value.type === attrs[0].value.type))
}
