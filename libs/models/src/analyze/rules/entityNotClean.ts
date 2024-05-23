import {z} from "zod";
import {Database, Entity, EntityId, EntityKind, EntityRef} from "../../database";
import {entityRefFromId, entityRefSame, entityToId, entityToRef} from "../../databaseUtils";
import {DatabaseQuery} from "../../interfaces/connector";
import {Rule, RuleConf, RuleId, RuleLevel, RuleName, RuleViolation} from "../rule";

const ruleId: RuleId = 'entity-not-clean'
const ruleName: RuleName = 'entity not clean'
const CustomRuleConf = RuleConf.extend({
    ignores: EntityId.array().optional(),
}).strict().describe('EntityNotCleanConf')
type CustomRuleConf = z.infer<typeof CustomRuleConf>
export const entityNotCleanRule: Rule<CustomRuleConf> = {
    id: ruleId,
    name: ruleName,
    conf: {level: RuleLevel.enum.high},
    zConf: CustomRuleConf,
    analyze(conf: CustomRuleConf, db: Database, queries: DatabaseQuery[]): RuleViolation[] {
        const now = db.stats?.extractedAt ? new Date(db.stats.extractedAt).getTime() : Date.now()
        const ignores: EntityRef[] = conf.ignores?.map(entityRefFromId) || []
        return (db.entities || [])
            .filter(e => isEntityNotClean(e, now))
            .filter(e => !ignores.some(i => entityRefSame(i, entityToRef(e))))
            .map(e => {
                const reason = isEntityNotClean(e, now)
                const value = isEntityNotCleanValue(e, now)
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

export function isEntityNotClean(entity: Entity, now: number): string {
    if ((entity.kind === undefined || entity.kind === EntityKind.enum.table) && entity.stats) {
        const s = entity.stats
        const oneDay = 24 * 60 * 60 * 1000
        if (s.rowsDead && s.rowsDead > 30000) return 'many dead rows'
        if (s.vacuumLag && s.vacuumLag > 30000) return 'high vacuum lag'
        if (s.analyzeLag&& s.analyzeLag > 30000) return 'high analyze lag'
        if (s.vacuumLast && now - new Date(s.vacuumLast).getTime() > oneDay) return 'old vacuum'
        if (s.analyzeLast && now - new Date(s.analyzeLast).getTime() > oneDay) return 'old analyze'
    }
    return ''
}

function isEntityNotCleanValue(entity: Entity, now: number): number | string {
    if ((entity.kind === undefined || entity.kind === EntityKind.enum.table) && entity.stats) {
        const s = entity.stats
        const oneDay = 24 * 60 * 60 * 1000
        if (s.rowsDead && s.rowsDead > 30000) return s.rowsDead
        if (s.vacuumLag && s.vacuumLag > 30000) return s.vacuumLag
        if (s.analyzeLag&& s.analyzeLag > 30000) return s.analyzeLag
        if (s.vacuumLast && now - new Date(s.vacuumLast).getTime() > oneDay) return s.vacuumLast
        if (s.analyzeLast && now - new Date(s.analyzeLast).getTime() > oneDay) return s.analyzeLast
    }
    return ''
}
