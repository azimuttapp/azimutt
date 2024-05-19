import {z} from "zod";
import {Database, Entity} from "../../database";
import {entityToId, entityToRef} from "../../databaseUtils";
import {DatabaseQuery} from "../../interfaces/connector";
import {Rule, RuleConf, RuleId, RuleLevel, RuleName, RuleViolation} from "../rule";

/**
 * Primary Keys are the default unique way to get a single row in a table.
 * They are also often used on foreign keys to reference a single record.
 * Having a primary key on every table is a common best practice.
 */

const ruleId: RuleId = 'primary-key-missing'
const ruleName: RuleName = 'missing primary key'
const CustomRuleConf = RuleConf
type CustomRuleConf = z.infer<typeof CustomRuleConf>
export const primaryKeyMissingRule: Rule<CustomRuleConf> = {
    id: ruleId,
    name: ruleName,
    conf: {level: RuleLevel.enum.high},
    zConf: CustomRuleConf,
    analyze(conf: CustomRuleConf, db: Database, queries: DatabaseQuery[]): RuleViolation[] {
        return (db.entities || []).filter(isPrimaryKeysMissing).map(e => ({
            ruleId,
            ruleName,
            ruleLevel: conf.level,
            entity: entityToRef(e),
            message: `Entity ${entityToId(e)} has no primary key.`
        }))
    }
}

// same as frontend/src/PagesComponents/Organization_/Project_/Views/Modals/SchemaAnalysis/PrimaryKeyMissing.elm
export function isPrimaryKeysMissing(entity: Entity): boolean {
    return !entity.pk && (entity.kind === undefined || entity.kind === 'table')
}
