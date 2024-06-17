import {z} from "zod";
import {isNotUndefined} from "@azimutt/utils";
import {Timestamp} from "../../common";
import {Database, Entity, EntityId, EntityRef} from "../../database";
import {entityRefFromId, entityRefSame, entityToId, entityToRef} from "../../databaseUtils";
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

const ruleId: RuleId = 'entity-too-large'
const ruleName: RuleName = 'entity too large'
const CustomRuleConf = RuleConf.extend({
    ignores: EntityId.array().optional(),
    max: z.number()
}).strict().describe('EntityTooLargeConf')
type CustomRuleConf = z.infer<typeof CustomRuleConf>
export const entityTooLargeRule: Rule<CustomRuleConf> = {
    id: ruleId,
    name: ruleName,
    conf: {level: RuleLevel.enum.medium, max: 30},
    zConf: CustomRuleConf,
    analyze(conf: CustomRuleConf, now: Timestamp, db: Database, queries: DatabaseQuery[], history: AnalyzeHistory[], reference: AnalyzeReportViolation[]): RuleViolation[] {
        const refIgnores: EntityRef[] = reference.map(r => r.entity).filter(isNotUndefined)
        const ignores: EntityRef[] = refIgnores.concat(conf.ignores?.map(entityRefFromId) || [])
        return (db.entities || [])
            .filter(e => isEntityTooLarge(e, conf.max))
            .filter(e => !ignores.some(i => entityRefSame(i, entityToRef(e))))
            .map(e => ({
                ruleId,
                ruleName,
                ruleLevel: conf.level,
                message: `Entity ${entityToId(e)} has too many attributes (${e.attrs.length}).`,
                entity: entityToRef(e),
                extra: {attributes: e.attrs.length}
            }))
    }
}

// same as frontend/src/PagesComponents/Organization_/Project_/Views/Modals/SchemaAnalysis/TableTooBig.elm
export function isEntityTooLarge(entity: Entity, max: number): boolean {
    return entity.attrs.length > max
}
