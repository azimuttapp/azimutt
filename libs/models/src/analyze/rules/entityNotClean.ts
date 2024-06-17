import {z} from "zod";
import {isNotUndefined} from "@azimutt/utils";
import {Timestamp} from "../../common";
import {Database, Entity, EntityId, EntityKind, EntityRef} from "../../database";
import {entityRefFromId, entityRefSame, entityToId, entityToRef} from "../../databaseUtils";
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

const ruleId: RuleId = 'entity-not-clean'
const ruleName: RuleName = 'entity not clean'
const CustomRuleConf = RuleConf.extend({
    ignores: EntityId.array().optional(),
    maxDeadRows: z.number(),
    maxVacuumLag: z.number(),
    maxAnalyzeLag: z.number(),
    maxVacuumDelayMs: z.number(),
    maxAnalyzeDelayMs: z.number(),
}).strict().describe('EntityNotCleanConf')
type CustomRuleConf = z.infer<typeof CustomRuleConf>
export const entityNotCleanRule: Rule<CustomRuleConf> = {
    id: ruleId,
    name: ruleName,
    conf: {level: RuleLevel.enum.high, maxDeadRows: 30000, maxVacuumLag: 30000, maxAnalyzeLag: 30000, maxVacuumDelayMs: oneDay, maxAnalyzeDelayMs: oneDay},
    zConf: CustomRuleConf,
    analyze(conf: CustomRuleConf, now: Timestamp, db: Database, queries: DatabaseQuery[], history: AnalyzeHistory[], reference: AnalyzeReportViolation[]): RuleViolation[] {
        const refIgnores: EntityRef[] = reference.map(r => r.entity).filter(isNotUndefined)
        const ignores: EntityRef[] = refIgnores.concat(conf.ignores?.map(entityRefFromId) || [])
        const dbDate = db.stats?.extractedAt ? new Date(db.stats.extractedAt).getTime() : now
        return (db.entities || [])
            .filter(e => isEntityNotClean(e, dbDate, conf.maxDeadRows, conf.maxVacuumLag, conf.maxAnalyzeLag, conf.maxVacuumDelayMs, conf.maxAnalyzeDelayMs))
            .filter(e => !ignores.some(i => entityRefSame(i, entityToRef(e))))
            .map(e => {
                const reason = isEntityNotClean(e, dbDate, conf.maxDeadRows, conf.maxVacuumLag, conf.maxAnalyzeLag, conf.maxVacuumDelayMs, conf.maxAnalyzeDelayMs)
                const value = isEntityNotCleanValue(e, dbDate, conf.maxDeadRows, conf.maxVacuumLag, conf.maxAnalyzeLag, conf.maxVacuumDelayMs, conf.maxAnalyzeDelayMs)
                return {
                    ruleId,
                    ruleName,
                    ruleLevel: conf.level,
                    message: `Entity ${entityToId(e)} has ${reason} (${value}).`,
                    entity: entityToRef(e),
                    extra: {reason, value}
                }
            })
    }
}

export function isEntityNotClean(entity: Entity, now: number, maxDeadRows: number, maxVacuumLag: number, maxAnalyzeLag: number, maxVacuumDelayMs: number, maxAnalyzeDelayMs: number): string {
    if ((entity.kind === undefined || entity.kind === EntityKind.enum.table) && entity.stats) {
        const s = entity.stats
        if (s.rowsDead && s.rowsDead > maxDeadRows) return 'many dead rows'
        if (s.vacuumLag && s.vacuumLag > maxVacuumLag) return 'high vacuum lag'
        if (s.analyzeLag&& s.analyzeLag > maxAnalyzeLag) return 'high analyze lag'
        if (s.vacuumLast && now - new Date(s.vacuumLast).getTime() > maxVacuumDelayMs) return 'old vacuum'
        if (s.analyzeLast && now - new Date(s.analyzeLast).getTime() > maxAnalyzeDelayMs) return 'old analyze'
    }
    return ''
}

function isEntityNotCleanValue(entity: Entity, now: number, maxDeadRows: number, maxVacuumLag: number, maxAnalyzeLag: number, maxVacuumDelayMs: number, maxAnalyzeDelayMs: number): number | string {
    if ((entity.kind === undefined || entity.kind === EntityKind.enum.table) && entity.stats) {
        const s = entity.stats
        if (s.rowsDead && s.rowsDead > maxDeadRows) return s.rowsDead
        if (s.vacuumLag && s.vacuumLag > maxVacuumLag) return s.vacuumLag
        if (s.analyzeLag&& s.analyzeLag > maxAnalyzeLag) return s.analyzeLag
        if (s.vacuumLast && now - new Date(s.vacuumLast).getTime() > maxVacuumDelayMs) return s.vacuumLast
        if (s.analyzeLast && now - new Date(s.analyzeLast).getTime() > maxAnalyzeDelayMs) return s.analyzeLast
    }
    return ''
}
