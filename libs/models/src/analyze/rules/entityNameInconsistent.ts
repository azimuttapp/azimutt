import {z} from "zod";
import {
    compatibleCases,
    isCamelLower,
    isCamelUpper,
    isKebabLower,
    isKebabUpper,
    isNotUndefined,
    isSnakeLower,
    isSnakeUpper,
    StringCase
} from "@azimutt/utils";
import {Timestamp} from "../../common";
import {Database, Entity, EntityId, EntityRef} from "../../database";
import {entityRefFromId, entityRefSame, entityRefToId, entityToRef} from "../../databaseUtils";
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
 * Keeping the same naming convention for all your tables will help avoid typos and understand things.
 */

const ruleId: RuleId = 'entity-name-inconsistent'
const ruleName: RuleName = 'inconsistent entity name'
const CustomRuleConf = RuleConf.extend({
    ignores: EntityId.array().optional(),
}).strict().describe('EntityNameInconsistentConf')
type CustomRuleConf = z.infer<typeof CustomRuleConf>
export const entityNameInconsistentRule: Rule<CustomRuleConf> = {
    id: ruleId,
    name: ruleName,
    conf: {level: RuleLevel.enum.low},
    zConf: CustomRuleConf,
    analyze(conf: CustomRuleConf, now: Timestamp, db: Database, queries: DatabaseQuery[], history: AnalyzeHistory[], reference: AnalyzeReportViolation[]): RuleViolation[] {
        const refIgnores: EntityRef[] = reference.map(r => r.entity).filter(isNotUndefined)
        const ignores: EntityRef[] = refIgnores.concat(conf.ignores?.map(entityRefFromId) || [])
        const inconsistencies = checkNamingConsistency(db.entities || [])
        return inconsistencies.invalid
            .filter(e => !ignores.some(i => entityRefSame(i, e)))
            .map(entity => ({
                ruleId,
                ruleName,
                ruleLevel: conf.level,
                message: `Entity ${entityRefToId(entity)} doesn't follow naming convention ${inconsistencies.convention}.`,
                entity: entity
            }))
    }
}

export type ConsistencyCheck = { convention: StringCase, invalid: EntityRef[] }

// same as frontend/src/PagesComponents/Organization_/Project_/Views/Modals/SchemaAnalysis/NamingConsistency.elm
export function checkNamingConsistency(entities: Entity[]): ConsistencyCheck {
    const counts = entities.reduce((acc, entity) => addCases(acc, entity.name), {} as Record<StringCase, number>)
    const entityCase = bestCase(counts)
    return {
        convention: entityCase.name,
        invalid: entities.filter(e => !entityCase.isValid(e.name)).map(entityToRef)
    }
}

export function bestCase(counts: Record<StringCase, number>): { name: StringCase, isValid: (v: string) => boolean } {
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

export function addCases(acc: Record<StringCase, number>, value: string): Record<StringCase, number> {
    return compatibleCases(value).reduce((acc, c) => ({...acc, [c]: (acc[c] || 0) + 1}), acc)
}
