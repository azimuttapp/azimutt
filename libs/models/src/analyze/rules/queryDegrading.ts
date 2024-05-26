import {z} from "zod";
import {indexBy, isNotUndefined, maxBy, removeUndefined} from "@azimutt/utils";
import {Duration, Millis, Percent, Timestamp} from "../../common";
import {Database} from "../../database";
import {entityRefToId} from "../../databaseUtils";
import {oneDay, oneMonth, showDate} from "../../helpers/date";
import {computePercent, showPercent} from "../../helpers/percent";
import {formatSql, getEntities, getMainEntity} from "../../helpers/sql";
import {DatabaseQuery, QueryId} from "../../interfaces/connector";
import {AnalyzeHistory, Rule, RuleConf, RuleId, RuleLevel, RuleName, RuleViolation} from "../rule";

const ruleId: RuleId = 'query-degrading'
const ruleName: RuleName = 'degrading query'
const CustomRuleConf = RuleConf.extend({
    ignores: QueryId.array().optional(),
    minExec: z.number(),
    maxDegradation: Percent,
    maxDegradationMonthly: Percent,
    maxDegradationDaily: Percent,
}).strict().describe('QueryDegradingConf')
type CustomRuleConf = z.infer<typeof CustomRuleConf>
export const queryDegradingRule: Rule<CustomRuleConf> = {
    id: ruleId,
    name: ruleName,
    conf: {level: RuleLevel.enum.high, minExec: 10, maxDegradation: 1, maxDegradationMonthly: 0.2, maxDegradationDaily: 0.1},
    zConf: CustomRuleConf,
    analyze(conf: CustomRuleConf, now: Timestamp, db: Database, queries: DatabaseQuery[], history: AnalyzeHistory[]): RuleViolation[] {
        const historyQueriesById: {report: string, date: Timestamp, queries: Record<QueryId, DatabaseQuery>}[] =
            history.map(h => ({report: h.report, date: h.date, queries: indexBy(h.queries, q => q.id)}))
        return queries
            .filter(q => !(conf.ignores || []).some(i => i === q.id))
            .map(query => {
                const previous: {report: string, date: Timestamp, query: DatabaseQuery}[] = historyQueriesById.map(h => {
                    const queryHist = h.queries[query.id]
                    return queryHist ? {report: h.report, date: h.date, query: queryHist} : undefined
                }).filter(isNotUndefined)
                return getDegradingQuery(now, query, previous, conf.minExec, conf.maxDegradation, conf.maxDegradationMonthly, conf.maxDegradationDaily)
            })
            .filter(isNotUndefined)
            .sort((a, b) => -(a.daily - b.daily))
            .map(r => {
                const entity = getMainEntity(r.current.query)
                const rate = r.period > oneMonth ? `${showPercent(r.monthly)} monthly, ` : r.period > oneDay ? `${showPercent(r.daily)} daily, ` : ''
                return removeUndefined({
                    ruleId,
                    ruleName,
                    ruleLevel: conf.level,
                    message: `Query ${r.current.id}${entity ? ` on ${entityRefToId(entity)}` : ''} degraded mean exec time by ${showPercent(r.degradation)} since ${showDate(r.date)} (${rate}${formatSql(r.current.query)}).`,
                    entity,
                    extra: {
                        queryId: r.current.id,
                        query: r.current.query,
                        degradationPercent: r.degradation,
                        periodMillis: r.period,
                        previousDate: new Date(r.date).toISOString(),
                        previousReport: r.report,
                        previousStats: queryStats(r.previous),
                        currentStats: queryStats(r.current),
                        entities: getEntities(r.current.query)
                    }
                })
            })
    }
}

function queryStats({id, database, query, ...stats}: DatabaseQuery) {
    return stats
}

type DegradingQuery = {report: string, date: Timestamp, previous: DatabaseQuery, current: DatabaseQuery, degradation: Percent, period: Duration, daily: Percent, monthly: Percent}

export function getDegradingQuery(now: Timestamp, query: DatabaseQuery, history: {report: string, date: Timestamp, query: DatabaseQuery}[], minExec: number, maxDegradation: Percent, maxDegradationMonthly: Percent, maxDegradationDaily: Percent): DegradingQuery | undefined {
    const count = query.exec?.count
    const meanTime = query.exec?.meanTime
    if (count && count >= minExec && meanTime) {
        const meanTimeHistory: {report: string, date: Timestamp, query: DatabaseQuery, count: number, meanTime: Millis}[] =
            history.map(h => h.query.exec?.count && h.query.exec?.meanTime ? {report: h.report, date: h.date, query: h.query, count: h.query.exec.count, meanTime: h.query.exec.meanTime} : undefined).filter(isNotUndefined)
        const degradations: DegradingQuery[] = meanTimeHistory.filter(p => p.count >= minExec).map(previous => {
            const period = now - previous.date
            const degradation = computePercent(previous.meanTime, meanTime)
            const daily = degradation / (period / oneDay)
            const monthly = degradation / (period / oneMonth)
            if (degradation >= maxDegradation || (period > oneDay && daily >= maxDegradationDaily) || (period > oneMonth && monthly >= maxDegradationMonthly)) {
                return {report: previous.report, date: previous.date, previous: previous.query, current: query, degradation, period, daily, monthly}
            } else {
                return undefined
            }
        }).filter(isNotUndefined)
        // return maxBy(degradations, d => d.since) // earliest degradation
        return maxBy(degradations, d => d.daily) // worst degradation
    }
    return undefined
}
