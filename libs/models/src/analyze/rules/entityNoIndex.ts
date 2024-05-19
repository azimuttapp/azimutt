import {z} from "zod";
import {Database, Entity} from "../../database";
import {entityToId, entityToRef} from "../../databaseUtils";
import {DatabaseQuery} from "../../interfaces/connector";
import {Rule, RuleConf, RuleId, RuleLevel, RuleName, RuleViolation} from "../rule";

const ruleId: RuleId = 'entity-no-index'
const ruleName: RuleName = 'entity no index'
const CustomRuleConf = RuleConf
type CustomRuleConf = z.infer<typeof CustomRuleConf>
export const entityNoIndexRule: Rule<CustomRuleConf> = {
    id: ruleId,
    name: ruleName,
    conf: {level: RuleLevel.enum.high},
    zConf: CustomRuleConf,
    analyze(conf: CustomRuleConf, db: Database, queries: DatabaseQuery[]): RuleViolation[] {
        return (db.entities || []).filter(hasEntityNoIndex).map(e => ({
            ruleId,
            ruleName,
            ruleLevel: conf.level,
            entity: entityToRef(e),
            message: `Entity ${entityToId(e)} has no index.`
        }))
    }
}

// same as frontend/src/PagesComponents/Organization_/Project_/Views/Modals/SchemaAnalysis/TableWithoutIndex.elm
export function hasEntityNoIndex(entity: Entity): boolean {
    return entity.pk === undefined && (entity.indexes || []).length === 0
}
