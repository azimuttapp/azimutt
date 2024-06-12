import {z} from "zod";
import {filterValues, groupBy, isNotUndefined, pluralize} from "@azimutt/utils";
import {Timestamp} from "../../common";
import {Attribute, AttributeName, AttributeRef, AttributeType, Database, Entity} from "../../database";
import {attributeRefToId, entityToRef, flattenAttribute} from "../../databaseUtils";
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
 * There is nothing wrong with inconsistent types on columns with identical name.
 * But sometimes, it's a hint of a same value or concept stored with a different format and may cause issues or misunderstandings.
 * Of course, not every column with the same name stores the exact same thing, and it may be totally fine.
 * Just have a look to be aware, and fix what need to be fixed.
 */

const ruleId: RuleId = 'attribute-type-inconsistent'
const ruleName: RuleName = 'inconsistent attribute type'
const CustomRuleConf = RuleConf.extend({
    ignores: AttributeName.array().optional()
}).strict().describe('AttributeTypeInconsistentConf')
type CustomRuleConf = z.infer<typeof CustomRuleConf>
export const attributeTypeInconsistentRule: Rule<CustomRuleConf> = {
    id: ruleId,
    name: ruleName,
    conf: {level: RuleLevel.enum.hint},
    zConf: CustomRuleConf,
    analyze(conf: CustomRuleConf, now: Timestamp, db: Database, queries: DatabaseQuery[], history: AnalyzeHistory[], reference: AnalyzeReportViolation[]): RuleViolation[] {
        const refIgnores: AttributeName[] = reference.map(r => r.attribute?.[0]).filter(isNotUndefined)
        const ignores: AttributeName[] = refIgnores.concat(conf.ignores || [])
        return Object.entries(getInconsistentAttributeTypes(db.entities || []))
            .filter(([name,]) => !ignores.some(i => i === name))
            .map(([name, refs]) => {
                const refsByType: [AttributeType, AttributeWithRef[]][] = Object.entries(groupBy(refs, r => r.value.type)).sort(([, a], [, b]) => a.length - b.length)
                const message = `Attribute ${name} has several types: ${refsByType.map(([t, [r, ...others]]) => `${t} in ${attributeRefToId(r.ref)}${others.length > 0 ? ` and ${pluralize(others.length, 'other')}` : ''}`).join(', ')}.`
                const {attribute, ...entity} = refsByType[0][1][0].ref
                const attributes = refs.map(r => ({...r.ref, type: r.value.type}))
                return {ruleId, ruleName, ruleLevel: conf.level, message, entity, attribute: [name], extra: {attributes}}
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
