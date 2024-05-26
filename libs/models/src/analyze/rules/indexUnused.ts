import {z} from "zod";
import {indexBy, isNotUndefined, minBy, removeUndefined} from "@azimutt/utils";
import {Timestamp} from "../../common";
import {ConstraintName, Database, Entity, EntityId, EntityRef, Index} from "../../database";
import {attributePathToId, entityRefFromId, entityRefSame, entityToId, entityToRef} from "../../databaseUtils";
import {DatabaseQuery} from "../../interfaces/connector";
import {AnalyzeHistory, Rule, RuleConf, RuleId, RuleLevel, RuleName, RuleViolation} from "../rule";
import {oneDay, showDate} from "../../helpers/date";

const ruleId: RuleId = 'index-unused'
const ruleName: RuleName = 'unused index'
const CustomRuleConf = RuleConf.extend({
    ignores: z.object({entity: EntityId, indexes: ConstraintName.array()}).array().optional(),
    minDays: z.number()
}).strict().describe('IndexUnusedConf')
type CustomRuleConf = z.infer<typeof CustomRuleConf>
export const indexUnusedRule: Rule<CustomRuleConf> = {
    id: ruleId,
    name: ruleName,
    conf: {level: RuleLevel.enum.medium, minDays: 10},
    zConf: CustomRuleConf,
    analyze(conf: CustomRuleConf, now: Timestamp, db: Database, queries: DatabaseQuery[], history: AnalyzeHistory[]): RuleViolation[] {
        const ignores: {entity: EntityRef, indexes: ConstraintName[]}[] = conf.ignores?.map(i => ({entity: entityRefFromId(i.entity), indexes: i.indexes})) || []
        const historyEntitiesById: {report: string, date: Timestamp, entities: Record<EntityId, Entity>}[] =
            history.map(h => ({report: h.report, date: h.date, entities: indexBy(h.database.entities || [], entityToId)}))
        return (db.entities || [])
            .flatMap(e => (e.indexes || []).map(i => ({entity: e, index: i})))
            .filter(e => !ignores.some(i => entityRefSame(i.entity, entityToRef(e.entity)) && i.indexes.includes(e.index.name || '')))
            .map(e => {
                const previous = historyEntitiesById.map(h => {
                    const entity = h.entities[entityToId(e.entity)]
                    const index = entity ? entity.indexes?.find(i => i.name === e.index.name) : undefined
                    return entity && index ? {report: h.report, date: h.date, value: {entity, index}} : undefined
                }).filter(isNotUndefined)
                return isIndexUnused(now, e, previous, conf.minDays)
            })
            .filter(isNotUndefined)
            .map(r => ({
                ruleId,
                ruleName,
                ruleLevel: conf.level,
                message: `Index ${r.current.index.name}(${r.current.index.attrs.map(attributePathToId).join(', ')}) on ${entityToId(r.current.entity)} is unused since ${showDate(r.date)} (check all instances to be sure!).`,
                entity: entityToRef(r.current.entity),
                extra: removeUndefined({
                    previousReport: r.report,
                    previousDate: new Date(r.date).toISOString(),
                    previous: r.previous?.index?.stats,
                    current: r.current.index.stats,
                })
            }))
    }
}

type IndexWithEntity = {entity: Entity, index: Index}
type UnusedIndex = {date: Timestamp, current: IndexWithEntity, previous?: IndexWithEntity, report?: string}

export function isIndexUnused(now: Timestamp, current: IndexWithEntity, history: {report: string, date: Timestamp, value: IndexWithEntity}[], minDays: number): UnusedIndex | undefined {
    const {scans, scansLast} = current.index.stats || {}
    if (scans && scans > 0) {
        const sameAsCurrent = history.filter(h => now - h.date > minDays * oneDay).map(h =>
            h.value.index.stats?.scans === scans ? {date: h.date, current, previous: h.value, report: h.report} : undefined
        ).filter(isNotUndefined)
        const res = minBy(sameAsCurrent, d => d.date)
        if (res) return res
    }
    if (scansLast) {
        const lastScan = new Date(scansLast).getTime()
        if (now - lastScan > minDays * oneDay) {
            return {date: lastScan, current}
        }
    }
    return undefined
}
