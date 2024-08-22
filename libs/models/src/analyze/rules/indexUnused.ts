import {z} from "zod";
import {indexBy, isNotUndefined, minBy, removeUndefined} from "@azimutt/utils";
import {Timestamp} from "../../common";
import {ConstraintId, ConstraintRef, Database, Entity, EntityId, Index} from "../../database";
import {attributePathToId, constraintRefFromId, constraintRefSame, entityToId, entityToRef} from "../../databaseUtils";
import {showDate} from "../../helpers/date";
import {oneDay} from "../../helpers/duration";
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

const ruleId: RuleId = 'index-unused'
const ruleName: RuleName = 'unused index'
const ruleDescription: string = 'indexes with the same number of scans during the threshold period or the last scan older than the threshold'
const CustomRuleConf = RuleConf.extend({
    ignores: ConstraintId.array().optional(),
    minDays: z.number()
}).strict().describe('IndexUnusedConf')
type CustomRuleConf = z.infer<typeof CustomRuleConf>
export const indexUnusedRule: Rule<CustomRuleConf> = {
    id: ruleId,
    name: ruleName,
    description: ruleDescription,
    conf: {level: RuleLevel.enum.medium, minDays: 10},
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
                    index: r.current.index,
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
