import {z} from "zod";
import {indexBy, isNotUndefined, maxBy, removeUndefined} from "@azimutt/utils";
import {Percent, Timestamp} from "../../common";
import {ConstraintId, ConstraintRef, Database, Entity, EntityId, Index} from "../../database";
import {attributePathToId, constraintRefFromId, constraintRefSame, entityToId, entityToRef} from "../../databaseUtils";
import {Bytes, Mo, showBytes} from "../../helpers/bytes";
import {showDate} from "../../helpers/date";
import {Duration, oneDay, oneMonth, oneYear} from "../../helpers/duration";
import {computePercent, showPercent} from "../../helpers/percent";
import {DatabaseQuery} from "../../interfaces/connector";
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

const ruleId: RuleId = 'index-grow-fast'
const ruleName: RuleName = 'fast growing index'
const CustomRuleConf = RuleConf.extend({
    ignores: ConstraintId.array().optional(),
    minSize: Bytes,
    maxGrowthYearly: Percent,
    maxGrowthMonthly: Percent,
    maxGrowthDaily: Percent,
}).strict().describe('IndexGrowFastConf')
type CustomRuleConf = z.infer<typeof CustomRuleConf>
export const indexGrowFastRule: Rule<CustomRuleConf> = {
    id: ruleId,
    name: ruleName,
    conf: {level: RuleLevel.enum.medium, minSize: 10 * Mo, maxGrowthYearly: 2, maxGrowthMonthly: 0.1, maxGrowthDaily: 0.01},
    zConf: CustomRuleConf,
    analyze(conf: CustomRuleConf, now: Timestamp, db: Database, queries: DatabaseQuery[], history: AnalyzeHistory[], reference: AnalyzeReportViolation[]): RuleViolation[] {
        const refIgnores: ConstraintRef[] = reference.map(r => r.entity && r.extra?.index?.name ? {...r.entity, constraint: r.extra.index.name} : undefined).filter(isNotUndefined)
        const ignores: ConstraintRef[] = refIgnores.concat(conf.ignores?.map(constraintRefFromId) || [])
        const historyEntitiesById: {report: string, date: Timestamp, entities: Record<EntityId, Entity>}[] =
            history.map(h => ({report: h.report, date: h.date, entities: indexBy(h.database.entities || [], entityToId)}))
        return (db.entities || [])
            .flatMap(e => (e.indexes || []).map(i => ({entity: e, index: i})))
            .filter(({entity, index: {name}}) => !(name && ignores.some(i => constraintRefSame(i, {...entityToRef(entity), constraint: name}))))
            .map(e => {
                const previous = historyEntitiesById.map(h => {
                    const entity = h.entities[entityToId(e.entity)]
                    const index = entity ? entity.indexes?.find(i => i.name === e.index.name) : undefined
                    return entity && index ? {report: h.report, date: h.date, value: {entity, index}} : undefined
                }).filter(isNotUndefined)
                return isIndexGrowingFast(now, e, previous, conf.minSize, conf.maxGrowthYearly, conf.maxGrowthMonthly, conf.maxGrowthDaily)
            })
            .filter(isNotUndefined)
            .map(r => {
                const name = `${r.current.index.name}(${r.current.index.attrs.map(attributePathToId).join(', ')}) on ${entityToId(r.current.entity)}`
                const rate = r.period > oneYear ? ` (${showPercent(r.yearly)} yearly)` : r.period > oneMonth ? ` (${showPercent(r.monthly)} monthly)` : r.period > oneDay ? ` (${showPercent(r.daily)} daily)` : ''
                return {
                    ruleId,
                    ruleName,
                    ruleLevel: conf.level,
                    message: `Index ${name} has grown by ${showPercent(r.growth)} (${showBytes(r.diff)}) since ${showDate(r.date)}${rate}.`,
                    entity: entityToRef(r.current.entity),
                    extra: removeUndefined({
                        previousReport: r.report,
                        previousDate: new Date(r.date).toISOString(),
                        periodMillis: r.period,
                        growth: r.growth,
                        previous: r.previous.index.stats,
                        current: r.current.index.stats,
                    })
                }
            })
    }
}

type IndexWithEntity = { entity: Entity, index: Index }
type GrowingIndex = { date: Timestamp, report: string, current: IndexWithEntity, previous: IndexWithEntity, diff: number, growth: Percent, period: Duration, daily: Percent, monthly: Percent, yearly: Percent }

export function isIndexGrowingFast(now: Timestamp, current: IndexWithEntity, history: {report: string, date: Timestamp, value: IndexWithEntity}[], minSize: Bytes, maxGrowthYearly: Percent, maxGrowthMonthly: Percent, maxGrowthDaily: Percent): GrowingIndex | undefined {
    const {size} = current.index.stats || {}
    if (size && size > minSize) {
        const fastGrowing = history.map(h => {
            const hSize = h.value.index.stats?.size
            const growth = hSize && size > hSize ? {value: size - hSize, percent: computePercent(hSize, size)} : undefined
            if (growth) {
                const period = now - h.date
                const daily = growth.percent / (period / oneDay)
                const monthly = growth.percent / (period / oneMonth)
                const yearly = growth.percent / (period / oneYear)
                if ((period > oneDay && daily > maxGrowthDaily) || (period > oneMonth && monthly > maxGrowthMonthly) || (period > oneYear && yearly > maxGrowthYearly)) {
                    return {date: h.date, report: h.report, current, previous: h.value, diff: growth.value, growth: growth.percent, period, daily, monthly, yearly}
                }
            }
        }).filter(isNotUndefined)
        return maxBy(fastGrowing, g => g.monthly)
    }
    return undefined
}
