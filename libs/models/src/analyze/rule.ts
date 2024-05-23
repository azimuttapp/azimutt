import {z, ZodType} from "zod";
import {AttributePath, Database, EntityRef} from "../database";
import {DatabaseQuery} from "../interfaces/connector";

export interface Rule<Conf extends RuleConf = RuleConf> {
    id: RuleId
    name: RuleName
    conf: Conf
    zConf: ZodType<Conf>
    analyze(conf: Conf, db: Database, queries: DatabaseQuery[]): RuleViolation[]
}

export const RuleId = z.string()
export type RuleId = z.infer<typeof RuleId>
export const RuleName = z.string()
export type RuleName = z.infer<typeof RuleName>
export const RuleLevel = z.enum(['high', 'medium', 'low', 'hint', 'off']) // from highest to lowest
export type RuleLevel = z.infer<typeof RuleLevel>
export const ruleLevelsShown = RuleLevel.options.filter(l => l !== RuleLevel.enum.off)
export const RuleConf = z.object({
    level: RuleLevel
}).strict().describe('RuleConf')
export type RuleConf = z.infer<typeof RuleConf>
export const RuleViolation = z.object({
    ruleId: RuleId,
    ruleName: RuleName,
    ruleLevel: RuleLevel,
    entity: EntityRef.optional(),
    attribute: AttributePath.optional(), // TODO: keep track of the column of violations
    message: z.string(),
}).strict()
export type RuleViolation = z.infer<typeof RuleViolation>
