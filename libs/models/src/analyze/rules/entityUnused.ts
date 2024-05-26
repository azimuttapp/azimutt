import {z} from "zod";
import {indexBy, isNotUndefined, minBy, removeUndefined} from "@azimutt/utils";
import {Timestamp} from "../../common";
import {Database, Entity, EntityId, EntityRef} from "../../database";
import {entityRefFromId, entityRefSame, entityToId, entityToRef} from "../../databaseUtils";
import {DatabaseQuery} from "../../interfaces/connector";
import {AnalyzeHistory, Rule, RuleConf, RuleId, RuleLevel, RuleName, RuleViolation} from "../rule";
import {oneDay, showDate} from "../../helpers/date";

const ruleId: RuleId = 'entity-unused'
const ruleName: RuleName = 'unused entity'
const CustomRuleConf = RuleConf.extend({
    ignores: EntityId.array().optional(),
    minDays: z.number()
}).strict().describe('EntityUnusedConf')
type CustomRuleConf = z.infer<typeof CustomRuleConf>
export const entityUnusedRule: Rule<CustomRuleConf> = {
    id: ruleId,
    name: ruleName,
    conf: {level: RuleLevel.enum.medium, minDays: 10},
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
                return isEntityUnused(now, e, previous, conf.minDays)
            })
            .filter(isNotUndefined)
            .map(r => ({
                ruleId,
                ruleName,
                ruleLevel: conf.level,
                message: `Entity ${entityToId(r.current)} is unused since ${showDate(r.date)} (check all instances to be sure!).`,
                entity: entityToRef(r.current),
                extra: removeUndefined({
                    previousReport: r.report,
                    previousDate: new Date(r.date).toISOString(),
                    previous: r.previous?.stats,
                    current: r.current.stats,
                })
            }))
    }
}

type UnusedEntity = {date: Timestamp, current: Entity, previous?: Entity, report?: string}

export function isEntityUnused(now: Timestamp, current: Entity, history: {report: string, date: Timestamp, entity: Entity}[], minDays: number): UnusedEntity | undefined {
    const {scanSeq, scanIdx, scanSeqLast, scanIdxLast} = current.stats || {}
    const scans = (scanSeq || 0) + (scanIdx || 0)
    if (scans > 0) {
        const sameAsCurrent = history.filter(h => now - h.date > minDays * oneDay).map(h => {
            const hScans = (h.entity.stats?.scanSeq || 0) + (h.entity.stats?.scanIdx || 0)
            return hScans === scans ? {date: h.date, current, previous: h.entity, report: h.report} : undefined
        }).filter(isNotUndefined)
        const res = minBy(sameAsCurrent, d => d.date)
        if (res) return res
    }
    if (scanSeqLast || scanIdxLast) {
        const lastSeqScan = scanSeqLast ? new Date(scanSeqLast).getTime() : 0
        const lastIdxScan = scanIdxLast ? new Date(scanIdxLast).getTime() : 0
        const lastScan = Math.max(lastSeqScan, lastIdxScan)
        if (now - lastScan > minDays * oneDay) {
            return {date: lastScan, current}
        }
    }
    return undefined
}
