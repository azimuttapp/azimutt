import {z} from "zod";
import {Timestamp} from "../../common";
import {Database, Entity, EntityId, EntityRef} from "../../database";
import {entityRefFromId, entityRefSame, entityToId, entityToRef} from "../../databaseUtils";
import {DatabaseQuery} from "../../interfaces/connector";
import {AnalyzeHistory, Rule, RuleConf, RuleId, RuleLevel, RuleName, RuleViolation} from "../rule";

/**
 * Primary Keys are the default unique way to get a single row in a table.
 * They are also often used on foreign keys to reference a single record.
 * Having a primary key on every table is a common best practice.
 */

const ruleId: RuleId = 'primary-key-missing'
const ruleName: RuleName = 'missing primary key'
const CustomRuleConf = RuleConf.extend({
    ignores: EntityId.array().optional(),
}).strict().describe('PrimaryKeyMissingConf')
type CustomRuleConf = z.infer<typeof CustomRuleConf>
export const primaryKeyMissingRule: Rule<CustomRuleConf> = {
    id: ruleId,
    name: ruleName,
    conf: {level: RuleLevel.enum.high},
    zConf: CustomRuleConf,
    analyze(conf: CustomRuleConf, now: Timestamp, db: Database, queries: DatabaseQuery[], history: AnalyzeHistory[]): RuleViolation[] {
        const ignores: EntityRef[] = conf.ignores?.map(entityRefFromId) || []
        return (db.entities || [])
            .filter(isPrimaryKeysMissing)
            .filter(e => !ignores.some(i => entityRefSame(i, entityToRef(e))))
            .map(e => ({
                ruleId,
                ruleName,
                ruleLevel: conf.level,
                message: `Entity ${entityToId(e)} has no primary key.`,
                entity: entityToRef(e)
            }))
    }
}

// same as frontend/src/PagesComponents/Organization_/Project_/Views/Modals/SchemaAnalysis/PrimaryKeyMissing.elm
export function isPrimaryKeysMissing(entity: Entity): boolean {
    return !entity.pk && (entity.kind === undefined || entity.kind === 'table')
}
