import {filterValues, groupBy} from "@azimutt/utils";
import {Attribute, AttributeName, AttributeRef, Database, Entity} from "../../database";
import {attributeRefToId, entityToRef, flattenAttribute} from "../../databaseUtils";
import {Rule, RuleId, RuleLevel, RuleName, RuleViolation} from "../rule";

/**
 * There is nothing wrong with inconsistent types on columns with identical name.
 * But sometimes, it's a hint of a same value or concept stored with a different format and may cause issues or misunderstandings.
 * Of course, not every column with the same name stores the exact same thing, and it may be totally fine.
 * Just have a look to be aware, and fix what need to be fixed.
 */

const ruleId: RuleId = 'attribute-type-inconsistent'
const ruleName: RuleName = 'inconsistent attribute type'
const ruleLevel: RuleLevel = RuleLevel.enum.hint
export const attributeTypeInconsistentRule: Rule = {
    id: ruleId,
    name: ruleName,
    level: ruleLevel,
    analyze(db: Database): RuleViolation[] {
        return Object.entries(getInconsistentAttributeTypes(db.entities || [])).map(([attrName, refs]) => {
            const refsByType = Object.entries(groupBy(refs, r => r.value.type)).sort(([, a], [, b]) => a.length - b.length)
            const {attribute, ...entity} = refsByType[0][1][0].ref
            const message = `Attribute ${attrName} has several types: ${refsByType.map(([t, [r]]) => `${t} in ${attributeRefToId(r.ref)}`).join(', ')}.`
            return {ruleId, ruleName, ruleLevel, entity, message}
        })
    }
}

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
