import {z} from "zod";
import {Timestamp} from "../../common";
import {Database, Entity, EntityId, EntityKind, EntityRef} from "../../database";
import {entityRefFromId, entityRefSame, entityToId, entityToRef} from "../../databaseUtils";
import {DatabaseQuery} from "../../interfaces/connector";
import {AnalyzeHistory, Rule, RuleConf, RuleId, RuleLevel, RuleName, RuleViolation} from "../rule";

const ruleId: RuleId = 'entity-index-none'
const ruleName: RuleName = 'entity without index'
const CustomRuleConf = RuleConf.extend({
    ignores: EntityId.array().optional(),
}).strict().describe('EntityIndexNoneConf')
type CustomRuleConf = z.infer<typeof CustomRuleConf>
export const entityIndexNoneRule: Rule<CustomRuleConf> = {
    id: ruleId,
    name: ruleName,
    conf: {level: RuleLevel.enum.high},
    zConf: CustomRuleConf,
    analyze(conf: CustomRuleConf, now: Timestamp, db: Database, queries: DatabaseQuery[], history: AnalyzeHistory[]): RuleViolation[] {
        const ignores: EntityRef[] = conf.ignores?.map(entityRefFromId) || []
        return (db.entities || []).filter(hasNoIndex)
            .filter(e => !ignores.some(i => entityRefSame(i, entityToRef(e))))
            .map(e => ({
                ruleId,
                ruleName,
                ruleLevel: conf.level,
                message: `Entity ${entityToId(e)} has no index.`,
                entity: entityToRef(e),
            }))
    }
}

// same as frontend/src/PagesComponents/Organization_/Project_/Views/Modals/SchemaAnalysis/TableWithoutIndex.elm
export function hasNoIndex(entity: Entity): boolean {
    return (entity.kind === undefined || entity.kind === EntityKind.enum.table) && entity.pk === undefined && (entity.indexes || []).length === 0
}
