import {z} from "zod";
import {removeUndefined} from "@azimutt/utils";
import {Database} from "../../database";
import {entityRefToId} from "../../databaseUtils";
import {DatabaseQuery, QueryId} from "../../interfaces/connector";
import {formatSql, getEntities, getMainEntity} from "../../helpers/sql";
import {formatMs} from "../../helpers/time";
import {Rule, RuleConf, RuleId, RuleLevel, RuleName, RuleViolation} from "../rule";

const ruleId: RuleId = 'query-high-variation'
const ruleName: RuleName = 'query with high variation'
const CustomRuleConf = RuleConf.extend({
    ignores: QueryId.array().optional(),
}).strict().describe('QueryHighVariationConf')
type CustomRuleConf = z.infer<typeof CustomRuleConf>
export const queryHighVariationRule: Rule<CustomRuleConf> = {
    id: ruleId,
    name: ruleName,
    conf: {level: RuleLevel.enum.hint},
    zConf: CustomRuleConf,
    analyze(conf: CustomRuleConf, db: Database, queries: DatabaseQuery[]): RuleViolation[] {
        return queries
            .filter(q => !(conf.ignores || []).some(i => i === q.id))
            .sort((a, b) => -((a.exec?.sdTime || 0) - (b.exec?.sdTime || 0)))
            .slice(0, 20)
            .map(q => {
                const entity = getMainEntity(q.query)
                const sd = formatMs(q.exec?.sdTime || 0)
                const min = formatMs(q.exec?.minTime || 0)
                const max = formatMs(q.exec?.maxTime || 0)
                return removeUndefined({
                    ruleId,
                    ruleName,
                    ruleLevel: conf.level,
                    message: `Query ${q.id}${entity ? ` on ${entityRefToId(entity)}` : ''} has high variation, with ${sd} standard deviation and execution time ranging from ${min} to ${max} (${formatSql(q.query)})`,
                    entity,
                    extra: {query: q, entities: getEntities(q.query)}
                })
            })
    }
}
