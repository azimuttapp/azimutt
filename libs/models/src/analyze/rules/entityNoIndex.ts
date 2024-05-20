import {z} from "zod";
import {Database, Entity, EntityId, EntityKind, EntityRef} from "../../database";
import {entityRefFromId, entityRefSame, entityToId, entityToRef} from "../../databaseUtils";
import {DatabaseQuery} from "../../interfaces/connector";
import {Rule, RuleConf, RuleId, RuleLevel, RuleName, RuleViolation} from "../rule";

const ruleId: RuleId = 'entity-no-index'
const ruleName: RuleName = 'entity no index'
const CustomRuleConf = RuleConf.extend({
    ignores: EntityId.array().optional(),
}).strict().describe('EntityNoIndexConf')
type CustomRuleConf = z.infer<typeof CustomRuleConf>
export const entityNoIndexRule: Rule<CustomRuleConf> = {
    id: ruleId,
    name: ruleName,
    conf: {level: RuleLevel.enum.high},
    zConf: CustomRuleConf,
    analyze(conf: CustomRuleConf, db: Database, queries: DatabaseQuery[]): RuleViolation[] {
        const ignores: EntityRef[] = conf.ignores?.map(entityRefFromId) || []
        return (db.entities || []).filter(hasEntityNoIndex)
            .filter(e => !ignores.some(i => entityRefSame(i, entityToRef(e))))
            .map(e => ({
                ruleId,
                ruleName,
                ruleLevel: conf.level,
                entity: entityToRef(e),
                message: `Entity ${entityToId(e)} has no index.`
            }))
    }
}

// same as frontend/src/PagesComponents/Organization_/Project_/Views/Modals/SchemaAnalysis/TableWithoutIndex.elm
export function hasEntityNoIndex(entity: Entity): boolean {
    return (entity.kind === undefined || entity.kind === EntityKind.enum.table) && entity.pk === undefined && (entity.indexes || []).length === 0
}
