import {z} from "zod";
import {isNotUndefined, StringCase} from "@azimutt/utils";
import {Timestamp} from "../../common";
import {AttributeId, AttributeRef, Database, Entity} from "../../database";
import {
    attributeRefFromId,
    attributeRefSame,
    attributeRefToId,
    entityRefFromAttribute,
    entityToRef,
    flattenAttribute
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
import {addCases, bestCase} from "./entityNameInconsistent";

/**
 * Keeping the same naming convention for all your columns will help avoid typos and understand things.
 */

const ruleId: RuleId = 'attribute-name-inconsistent'
const ruleName: RuleName = 'inconsistent attribute name'
const ruleDescription: string = 'attributes with names not following the most common convention among attribute names'
const CustomRuleConf = RuleConf.extend({
    ignores: AttributeId.array().optional(),
}).strict().describe('AttributeNameInconsistentConf')
type CustomRuleConf = z.infer<typeof CustomRuleConf>
export const attributeNameInconsistentRule: Rule<CustomRuleConf> = {
    id: ruleId,
    name: ruleName,
    description: ruleDescription,
    conf: {level: RuleLevel.enum.low},
    zConf: CustomRuleConf,
    analyze(conf: CustomRuleConf, now: Timestamp, db: Database, queries: DatabaseQuery[], history: AnalyzeHistory[], reference: AnalyzeReportViolation[]): RuleViolation[] {
        const refIgnores: AttributeRef[] = reference.map(r => r.entity && r.attribute ? {...r.entity, attribute: r.attribute} : undefined).filter(isNotUndefined)
        const ignores: AttributeRef[] = refIgnores.concat(conf.ignores?.map(attributeRefFromId) || [])
        const inconsistencies = checkNamingConsistency(db.entities || [])
        return inconsistencies.invalid
            .filter(a => !ignores.some(i => attributeRefSame(i, a)))
            .map(attribute => ({
                ruleId,
                ruleName,
                ruleLevel: conf.level,
                message: `Attribute ${attributeRefToId(attribute)} doesn't follow naming convention ${inconsistencies.convention}.`,
                entity: entityRefFromAttribute(attribute),
                attribute: attribute.attribute
            }))
    }
}

export type ConsistencyCheck = { convention: StringCase, invalid: AttributeRef[] }

// same as frontend/src/PagesComponents/Organization_/Project_/Views/Modals/SchemaAnalysis/NamingConsistency.elm
export function checkNamingConsistency(entities: Entity[]): ConsistencyCheck {
    const counts = entities.reduce((acc, entity) =>
        (entity.attrs || []).flatMap(a => flattenAttribute(a)).reduce((acc, a) => addCases(acc, a.attr.name), acc),
        {} as Record<StringCase, number>
    )
    const attributeCase = bestCase(counts)
    return {
        convention: attributeCase.name,
        invalid: entities.flatMap(e => (e.attrs || []).flatMap(a => flattenAttribute(a)).filter(a => !attributeCase.isValid(a.attr.name)).map(a => ({...entityToRef(e), attribute: a.path})))
    }
}
