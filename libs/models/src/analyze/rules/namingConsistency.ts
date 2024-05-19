import {z} from "zod";
import {
    compatibleCases,
    isCamelLower,
    isCamelUpper,
    isKebabLower,
    isKebabUpper,
    isSnakeLower,
    isSnakeUpper,
    StringCase
} from "@azimutt/utils";
import {AttributeRef, Database, Entity, EntityRef} from "../../database";
import {
    attributeRefToId,
    entityRefFromAttribute,
    entityRefToId,
    entityToRef,
    flattenAttribute
} from "../../databaseUtils";
import {DatabaseQuery} from "../../interfaces/connector";
import {Rule, RuleConf, RuleId, RuleLevel, RuleName, RuleViolation} from "../rule";

/**
 * Keeping the same naming convention for all your tables and columns will help avoid typos and understand things.
 */

const ruleId: RuleId = 'naming-consistency'
const ruleName: RuleName = 'naming consistency'
const CustomRuleConf = RuleConf
type CustomRuleConf = z.infer<typeof CustomRuleConf>
export const namingConsistencyRule: Rule<CustomRuleConf> = {
    id: ruleId,
    name: ruleName,
    conf: {level: RuleLevel.enum.low},
    zConf: CustomRuleConf,
    analyze(conf: CustomRuleConf, db: Database, queries: DatabaseQuery[]): RuleViolation[] {
        const inconsistencies = checkNamingConsistency(db.entities || [])
        const entities = inconsistencies.entities.invalid.map(entity => ({
            ruleId,
            ruleName,
            ruleLevel: conf.level,
            entity: entity,
            message: `Entity ${entityRefToId(entity)} doesn't follow naming convention ${inconsistencies.entities.convention}.`
        }))
        const attributes = inconsistencies.attributes.invalid.map(attribute => ({
            ruleId,
            ruleName,
            ruleLevel: conf.level,
            entity: entityRefFromAttribute(attribute),
            message: `Attribute ${attributeRefToId(attribute)} doesn't follow naming convention ${inconsistencies.attributes.convention}.`
        }))
        return entities.concat(attributes)
    }
}

export type ConsistencyCheck<T> = { convention: StringCase, invalid: T[] }
export type InconsistentNaming = { entities: ConsistencyCheck<EntityRef>, attributes: ConsistencyCheck<AttributeRef> }

// same as frontend/src/PagesComponents/Organization_/Project_/Views/Modals/SchemaAnalysis/NamingConsistency.elm
export function checkNamingConsistency(entities: Entity[]): InconsistentNaming {
    const counts = entities.reduce((acc, entity) => ({
        entities: addCases(acc.entities, entity.name),
        attributes: entity.attrs.flatMap(a => flattenAttribute(a)).reduce((acc, a) => addCases(acc, a.attr.name), acc.attributes)
    }), {entities: {}, attributes: {}} as {
        entities: Record<StringCase, number>,
        attributes: Record<StringCase, number>
    })
    const entityCase = bestCase(counts.entities)
    const attributeCase = bestCase(counts.attributes)
    return {
        entities: {
            convention: entityCase.name,
            invalid: entities.filter(e => !entityCase.isValid(e.name)).map(entityToRef)
        },
        attributes: {
            convention: attributeCase.name,
            invalid: entities.flatMap(e => e.attrs.flatMap(a => flattenAttribute(a)).filter(a => !attributeCase.isValid(a.attr.name)).map(a => ({...entityToRef(e), attribute: a.path})))
        }
    }
}

function bestCase(counts: Record<StringCase, number>): { name: StringCase, isValid: (v: string) => boolean } {
    const bestCase: StringCase = Object.entries(counts).reduce(([prevCase, prevCount], [curCase, curCount]) => {
        return curCount > prevCount ? [curCase, curCount] : [prevCase, prevCount]
    }, ['snake-lower', 0])[0] as StringCase
    return [
        {name: 'camel-upper' as const, isValid: isCamelUpper},
        {name: 'camel-lower' as const, isValid: isCamelLower},
        {name: 'snake-upper' as const, isValid: isSnakeUpper},
        {name: 'snake-lower' as const, isValid: isSnakeLower},
        {name: 'kebab-upper' as const, isValid: isKebabUpper},
        {name: 'kebab-lower' as const, isValid: isKebabLower},
    ].find(c => c.name === bestCase) || {name: 'snake-lower', isValid: isSnakeLower}
}

function addCases(acc: Record<StringCase, number>, value: string): Record<StringCase, number> {
    return compatibleCases(value).reduce((acc, c) => ({...acc, [c]: (acc[c] || 0) + 1}), acc)
}
