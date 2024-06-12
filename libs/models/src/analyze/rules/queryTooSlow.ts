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

const ruleId: RuleId = 'query-too-slow'
const ruleName: RuleName = 'too slow query'
const CustomRuleConf = RuleConf.extend({
    ignores: QueryId.array().optional(),
    maxMs: z.number(),
}).strict().describe('QueryTooSlowConf')
type CustomRuleConf = z.infer<typeof CustomRuleConf>
export const queryTooSlowRule: Rule<CustomRuleConf> = {
    id: ruleId,
    name: ruleName,
    conf: {level: RuleLevel.enum.high, maxMs: 1000},
    zConf: CustomRuleConf,
    analyze(conf: CustomRuleConf, now: Timestamp, db: Database, queries: DatabaseQuery[], history: AnalyzeHistory[], reference: AnalyzeReportViolation[]): RuleViolation[] {
        const refIgnores: QueryId[] = reference.map(r => r.extra?.queryId).filter(isNotUndefined)
        const ignores: QueryId[] = refIgnores.concat(conf.ignores || [])
        return queries
            .filter(q => isQueryTooSlow(q, conf.maxMs))
            .filter(q => !ignores.some(i => i === q.id))
            .sort((a, b) => -((a.exec?.meanTime || 0) - (b.exec?.meanTime || 0)))
            .map(q => {
                const entity = getMainEntity(q.query)
                const {id, database, query, ...stats} = q
                return removeUndefined({
                    ruleId,
                    ruleName,
                    ruleLevel: conf.level,
                    message: `Query ${q.id}${entity ? ` on ${entityRefToId(entity)}` : ''} is too slow (${showDuration(q.exec?.meanTime || 0)}, ${formatSql(q.query)}).`,
                    entity,
                    extra: {queryId: id, query, stats, entities: getEntities(q.query)}
                })
            })
    }
}

export function isQueryTooSlow(query: DatabaseQuery, maxMs: number): boolean {
    return (query.exec?.meanTime || 0) > maxMs
}
