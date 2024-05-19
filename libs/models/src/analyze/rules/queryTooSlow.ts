import {z} from "zod";
import {removeUndefined} from "@azimutt/utils";
import {Database} from "../../database";
import {entityRefToId} from "../../databaseUtils";
import {DatabaseQuery} from "../../interfaces/connector";
import {formatSql, getMainEntity} from "../../helpers/sql";
import {formatMs} from "../../helpers/time";
import {Rule, RuleConf, RuleId, RuleLevel, RuleName, RuleViolation} from "../rule";

const ruleId: RuleId = 'query-too-slow'
const ruleName: RuleName = 'query too slow'
const CustomRuleConf = RuleConf.extend({
    maxMs: z.number()
}).strict().describe('QueryTooSlowConf')
type CustomRuleConf = z.infer<typeof CustomRuleConf>
export const queryTooSlowRule: Rule<CustomRuleConf> = {
    id: ruleId,
    name: ruleName,
    conf: {level: RuleLevel.enum.high, maxMs: 1000},
    zConf: CustomRuleConf,
    analyze(conf: CustomRuleConf, db: Database, queries: DatabaseQuery[]): RuleViolation[] {
        return queries
            .filter(q => isQueryTooSlow(q, conf.maxMs))
            .sort((a, b) => -((a.exec?.meanTime || 0) - (b.exec?.meanTime || 0)))
            .map(q => {
                const entity = getMainEntity(q.query)
                return removeUndefined({
                    ruleId,
                    ruleName,
                    ruleLevel: conf.level,
                    entity,
                    message: `Query ${q.id}${entity ? ` on ${entityRefToId(entity)}` : ''} is too slow (${formatMs(q.exec?.meanTime || 0)}, ${formatSql(q.query)}).`
                })
            })
    }
}

export function isQueryTooSlow(query: DatabaseQuery, maxMs: number): boolean {
    return (query.exec?.meanTime || 0) > maxMs
}
