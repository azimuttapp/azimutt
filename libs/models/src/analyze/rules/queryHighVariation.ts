import {z} from "zod";
import {isNotUndefined, removeUndefined} from "@azimutt/utils";
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
    analyze(conf: CustomRuleConf, now: Timestamp, db: Database, queries: DatabaseQuery[], history: AnalyzeHistory[], reference: AnalyzeReportViolation[]): RuleViolation[] {
        const refIgnores: QueryId[] = reference.map(r => r.extra?.queryId).filter(isNotUndefined)
        const ignores: QueryId[] = refIgnores.concat(conf.ignores || [])
        return queries
            .filter(q => !ignores.some(i => i === q.id))
            .sort((a, b) => -((a.exec?.sdTime || 0) - (b.exec?.sdTime || 0)))
            .slice(0, 20)
            .map(q => {
                const entity = getMainEntity(q.query)
                const sd = showDuration(q.exec?.sdTime || 0)
                const min = showDuration(q.exec?.minTime || 0)
                const max = showDuration(q.exec?.maxTime || 0)
                const {id, database, query, ...stats} = q
                return removeUndefined({
                    ruleId,
                    ruleName,
                    ruleLevel: conf.level,
                    message: `Query ${q.id}${entity ? ` on ${entityRefToId(entity)}` : ''} has high variation, with ${sd} standard deviation and exec time ranging from ${min} to ${max} (${formatSql(q.query)})`,
                    entity,
                    extra: {queryId: id, query, stats, entities: getEntities(q.query)}
                })
            })
    }
}
