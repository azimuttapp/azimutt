import {z} from "zod";
import {indexBy, isNotUndefined, maxBy, pluralize, removeUndefined} from "@azimutt/utils";
import {Percent, Timestamp} from "../../common";
import {Database, Entity, EntityId, EntityRef} from "../../database";
import {entityRefFromId, entityRefSame, entityToId, entityToRef} from "../../databaseUtils";
import {Bytes, Mo, showBytes} from "../../helpers/bytes";
import {showDate} from "../../helpers/date";
import {Duration, oneDay, oneMonth, oneYear} from "../../helpers/duration";
import {computePercent, showPercent} from "../../helpers/percent";
import {DatabaseQuery} from "../../interfaces/connector";
import {AnalyzeHistory, Rule, RuleConf, RuleId, RuleLevel, RuleName, RuleViolation} from "../rule";

const ruleId: RuleId = 'entity-grow-fast'
const ruleName: RuleName = 'fast growing entity'
const CustomRuleConf = RuleConf.extend({
    ignores: EntityId.array().optional(),
    minRows: z.number(),
    minSize: Bytes,
    maxGrowthYearly: Percent,
    maxGrowthMonthly: Percent,
    maxGrowthDaily: Percent,
}).strict().describe('EntityGrowFastConf')
type CustomRuleConf = z.infer<typeof CustomRuleConf>
export const entityGrowFastRule: Rule<CustomRuleConf> = {
    id: ruleId,
    name: ruleName,
    conf: {level: RuleLevel.enum.medium, minRows: 10000, minSize: 10 * Mo, maxGrowthYearly: 2, maxGrowthMonthly: 0.1, maxGrowthDaily: 0.01},
    zConf: CustomRuleConf,
    analyze(conf: CustomRuleConf, now: Timestamp, db: Database, queries: DatabaseQuery[], history: AnalyzeHistory[]): RuleViolation[] {
        const ignores: EntityRef[] = conf.ignores?.map(entityRefFromId) || []
        const historyEntitiesById: {report: string, date: Timestamp, entities: Record<EntityId, Entity>}[] =
            history.map(h => ({report: h.report, date: h.date, entities: indexBy(h.database.entities || [], entityToId)}))
        return (db.entities || [])
            .filter(e => !ignores.some(i => entityRefSame(i, entityToRef(e))))
            .map(e => {
                const previous = historyEntitiesById.map(h => {
                    const entity = h.entities[entityToId(e)]
                    return entity ? {report: h.report, date: h.date, entity} : undefined
                }).filter(isNotUndefined)
                return isEntityGrowingFast(now, e, previous, conf.minRows, conf.minSize, conf.maxGrowthYearly, conf.maxGrowthMonthly, conf.maxGrowthDaily)
            })
            .filter(isNotUndefined)
            .map(r => {
                const diff = r.kind === 'size' ? showBytes(r.diff) : pluralize(r.diff, 'row')
                const rate = r.period > oneYear ? ` (${showPercent(r.yearly)} yearly)` : r.period > oneMonth ? ` (${showPercent(r.monthly)} monthly)` : r.period > oneDay ? ` (${showPercent(r.daily)} daily)` : ''
                return {
                    ruleId,
                    ruleName,
                    ruleLevel: conf.level,
                    message: `Entity ${entityToId(r.current)} has grown by ${showPercent(r.growth)} (${diff}) since ${showDate(r.date)}${rate}.`,
                    entity: entityToRef(r.current),
                    extra: removeUndefined({
                        previousReport: r.report,
                        previousDate: new Date(r.date).toISOString(),
                        periodMillis: r.period,
                        growth: r.growth,
                        kind: r.kind,
                        previous: r.previous?.stats,
                        current: r.current.stats,
                    })
                }
            })
    }
}

type Growth = { kind: 'rows' | 'size', value: number, percent: Percent }
type GrowingEntity = { date: Timestamp, report: string, current: Entity, previous: Entity, kind: 'rows' | 'size', diff: number, growth: Percent, period: Duration, daily: Percent, monthly: Percent, yearly: Percent }

export function isEntityGrowingFast(now: Timestamp, current: Entity, history: {report: string, date: Timestamp, entity: Entity}[], minRows: number, minSize: number, maxGrowthYearly: Percent, maxGrowthMonthly: Percent, maxGrowthDaily: Percent): GrowingEntity | undefined {
    const {rows, size} = current.stats || {}
    if ((rows && rows > minRows) || (size && size > minSize)) {
        const fastGrowing = history.map(h => {
            const hRows = h.entity.stats?.rows
            const hSize = h.entity.stats?.size
            const gRows: Growth | undefined = rows && hRows && rows > hRows ? {kind: 'rows' as const, value: rows - hRows, percent: computePercent(hRows, rows)} : undefined
            const gSize: Growth | undefined = size && hSize && size > hSize ? {kind: 'size' as const, value: size - hSize, percent: computePercent(hSize, size)} : undefined
            const growth: Growth | undefined = gRows && gSize ? (gRows.percent > gSize.percent ? gRows : gSize) : gRows || gSize
            if (growth) {
                const period = now - h.date
                const daily = growth.percent / (period / oneDay)
                const monthly = growth.percent / (period / oneMonth)
                const yearly = growth.percent / (period / oneYear)
                if ((period > oneDay && daily > maxGrowthDaily) || (period > oneMonth && monthly > maxGrowthMonthly) || (period > oneYear && yearly > maxGrowthYearly)) {
                    return {date: h.date, report: h.report, current, previous: h.entity, kind: growth.kind, diff: growth.value, growth: growth.percent, period, daily, monthly, yearly}
                }
            }
            return undefined
        }).filter(isNotUndefined)
        return maxBy(fastGrowing, g => g.monthly)
    }
    return undefined
}
