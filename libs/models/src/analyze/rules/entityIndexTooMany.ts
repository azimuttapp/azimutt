import {z} from "zod";
import {Database, Entity, EntityId, EntityRef} from "../../database";
import {entityRefFromId, entityRefSame, entityToId, entityToRef} from "../../databaseUtils";
import {DatabaseQuery} from "../../interfaces/connector";
import {Rule, RuleConf, RuleId, RuleLevel, RuleName, RuleViolation} from "../rule";

const ruleId: RuleId = 'entity-index-too-many'
const ruleName: RuleName = 'entity with too many indexes'
const CustomRuleConf = RuleConf.extend({
    ignores: EntityId.array().optional(),
    max: z.number(),
}).strict().describe('EntityIndexTooManyConf')
type CustomRuleConf = z.infer<typeof CustomRuleConf>
export const entityIndexTooManyRule: Rule<CustomRuleConf> = {
    id: ruleId,
    name: ruleName,
    conf: {level: RuleLevel.enum.medium, max: 20},
    zConf: CustomRuleConf,
    analyze(conf: CustomRuleConf, db: Database, queries: DatabaseQuery[]): RuleViolation[] {
        const ignores: EntityRef[] = conf.ignores?.map(entityRefFromId) || []
        return (db.entities || [])
            .filter(e => hasTooManyIndexes(e, conf.max))
            .filter(e => !ignores.some(i => entityRefSame(i, entityToRef(e))))
            .map(e => ({
                ruleId,
                ruleName,
                ruleLevel: conf.level,
                message: `Entity ${entityToId(e)} has too many indexes (${e.indexes?.length || 0}).`,
                entity: entityToRef(e),
                extra: {
                    count: e.indexes?.length || 0,
                    indexes: (e.indexes || []).map(({stats, extra, ...i}) => i)
                }
            }))
    }
}

export function hasTooManyIndexes(entity: Entity, max: number): boolean {
    return (entity.indexes?.length || 0) > max
}
