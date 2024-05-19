import {z} from "zod";
import {Database, Entity} from "../../database";
import {entityToId, entityToRef} from "../../databaseUtils";
import {DatabaseQuery} from "../../interfaces/connector";
import {Rule, RuleConf, RuleId, RuleLevel, RuleName, RuleViolation} from "../rule";

const ruleId: RuleId = 'entity-too-large'
const ruleName: RuleName = 'entity too large'
const CustomRuleConf = RuleConf.extend({
    max: z.number()
}).strict().describe('EntityTooLargeConf')
type CustomRuleConf = z.infer<typeof CustomRuleConf>
export const entityTooLargeRule: Rule<CustomRuleConf> = {
    id: ruleId,
    name: ruleName,
    conf: {level: RuleLevel.enum.medium, max: 30},
    zConf: CustomRuleConf,
    analyze(conf: CustomRuleConf, db: Database, queries: DatabaseQuery[]): RuleViolation[] {
        return (db.entities || []).filter(e => isEntityTooLarge(e, conf.max)).map(e => ({
            ruleId,
            ruleName,
            ruleLevel: conf.level,
            entity: entityToRef(e),
            message: `Entity ${entityToId(e)} has too many attributes (${e.attrs.length}).`
        }))
    }
}

// same as frontend/src/PagesComponents/Organization_/Project_/Views/Modals/SchemaAnalysis/TableTooBig.elm
export function isEntityTooLarge(entity: Entity, max: number): boolean {
    return entity.attrs.length > max
}
