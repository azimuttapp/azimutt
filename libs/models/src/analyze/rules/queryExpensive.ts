import {z} from "zod";
import {removeUndefined} from "@azimutt/utils";
import {Timestamp} from "../../common";
import {Database} from "../../database";
import {entityRefToId} from "../../databaseUtils";
import {DatabaseQuery, QueryId} from "../../interfaces/connector";
import {formatSql, getEntities, getMainEntity} from "../../helpers/sql";
import {formatMs} from "../../helpers/time";
import {AnalyzeHistory, Rule, RuleConf, RuleId, RuleLevel, RuleName, RuleViolation} from "../rule";

const ruleId: RuleId = 'query-expensive'
const ruleName: RuleName = 'expensive query'
const CustomRuleConf = RuleConf.extend({
    ignores: QueryId.array().optional(),
}).strict().describe('QueryExpensiveConf')
type CustomRuleConf = z.infer<typeof CustomRuleConf>
export const queryExpensiveRule: Rule<CustomRuleConf> = {
    id: ruleId,
    name: ruleName,
    conf: {level: RuleLevel.enum.hint},
    zConf: CustomRuleConf,
    analyze(conf: CustomRuleConf, now: Timestamp, db: Database, queries: DatabaseQuery[], history: AnalyzeHistory[]): RuleViolation[] {
        return queries
            .filter(q => !(conf.ignores || []).some(i => i === q.id))
            .sort((a, b) => -((a.exec?.sumTime || 0) - (b.exec?.sumTime || 0)))
            .slice(0, 20)
            .map(q => {
                const entity = getMainEntity(q.query)
                const {id, database, query, ...stats} = q
                return removeUndefined({
                    ruleId,
                    ruleName,
                    ruleLevel: conf.level,
                    message: `Query ${q.id}${entity ? ` on ${entityRefToId(entity)}` : ''} is one of the most expensive, cumulated ${formatMs(q.exec?.sumTime || 0)} (${formatSql(q.query)})`,
                    entity,
                    extra: {queryId: id, query, stats, entities: getEntities(q.query)}
                })
            })
    }
}
