import {z} from "zod";
import {prettyNumber} from "@azimutt/utils";
import {Timestamp} from "../../common";
import {Database, Entity, EntityId, EntityRef} from "../../database";
import {entityRefFromId, entityRefSame, entityToId, entityToRef} from "../../databaseUtils";
import {DatabaseQuery} from "../../interfaces/connector";
import {AnalyzeHistory, Rule, RuleConf, RuleId, RuleLevel, RuleName, RuleViolation} from "../rule";

const ruleId: RuleId = 'entity-index-too-heavy'
const ruleName: RuleName = 'entity with too heavy indexes'
const CustomRuleConf = RuleConf.extend({
    ignores: EntityId.array().optional(),
    ratio: z.number(),
}).strict().describe('EntityIndexTooHeavyConf')
type CustomRuleConf = z.infer<typeof CustomRuleConf>
export const entityIndexTooHeavyRule: Rule<CustomRuleConf> = {
    id: ruleId,
    name: ruleName,
    conf: {level: RuleLevel.enum.medium, ratio: 1},
    zConf: CustomRuleConf,
    analyze(conf: CustomRuleConf, now: Timestamp, db: Database, queries: DatabaseQuery[], history: AnalyzeHistory[]): RuleViolation[] {
        const ignores: EntityRef[] = conf.ignores?.map(entityRefFromId) || []
        return (db.entities || [])
            .filter(e => hasTooHeavyIndexes(e, conf.ratio))
            .filter(e => !ignores.some(i => entityRefSame(i, entityToRef(e))))
            .map(e => {
                const ratio = e.stats?.sizeIdx && e.stats?.size ? e.stats.sizeIdx / e.stats.size : 0
                return {
                    ruleId,
                    ruleName,
                    ruleLevel: conf.level,
                    message: `Entity ${entityToId(e)} has too heavy indexes (${prettyNumber(ratio)}x data size).`,
                    entity: entityToRef(e),
                    extra: {ratio}
                }
            })
            .sort((a, b) => -(a.extra.ratio - b.extra.ratio))
    }
}

export function hasTooHeavyIndexes(entity: Entity, ratio: number): boolean {
    return entity.stats?.sizeIdx && entity.stats?.size ? entity.stats.sizeIdx / entity.stats.size > ratio : false
}
