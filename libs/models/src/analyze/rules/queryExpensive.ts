import {z} from "zod";
import {isNotUndefined, pluralize, removeUndefined} from "@azimutt/utils";
import {Timestamp} from "../../common";
import {Database} from "../../database";
import {entityRefToId} from "../../databaseUtils";
import {showDuration} from "../../helpers/duration";
import {formatSql, getEntities, getMainEntity} from "../../helpers/sql";
import {DatabaseQuery, QueryId} from "../../interfaces/connector";
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
    analyze(conf: CustomRuleConf, now: Timestamp, db: Database, queries: DatabaseQuery[], history: AnalyzeHistory[], reference: AnalyzeReportViolation[]): RuleViolation[] {
        const refIgnores: QueryId[] = reference.map(r => r.extra?.queryId).filter(isNotUndefined)
        const ignores: QueryId[] = refIgnores.concat(conf.ignores || [])
        return queries
            .filter(q => !ignores.some(i => i === q.id))
            .sort((a, b) => -((a.exec?.sumTime || 0) - (b.exec?.sumTime || 0)))
            .slice(0, 20)
            .map(q => {
                const entity = getMainEntity(q.query)
                const {id, database, query, ...stats} = q
                return removeUndefined({
                    ruleId,
                    ruleName,
                    ruleLevel: conf.level,
                    message: `Query ${q.id}${entity ? ` on ${entityRefToId(entity)}` : ''} is one of the most expensive, cumulated ${showDuration(q.exec?.sumTime || 0)} exec time in ${pluralize(q.exec?.count || 0, 'execution')} (${formatSql(q.query)})`,
                    entity,
                    extra: {queryId: id, query, stats, entities: getEntities(q.query)}
                })
            })
    }
}
