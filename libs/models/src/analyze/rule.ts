import {z} from "zod";
import {AttributePath, Database, EntityRef} from "../database";

export interface Rule {
    id: RuleId
    name: RuleName
    level: RuleLevel
    analyze(db: Database): RuleViolation[]
}

export const RuleId = z.string()
export type RuleId = z.infer<typeof RuleId>
export const RuleName = z.string()
export type RuleName = z.infer<typeof RuleName>
export const RuleLevel = z.enum(['high', 'medium', 'low', 'hint']) // from highest to lowest
export type RuleLevel = z.infer<typeof RuleLevel>
export const RuleViolation = z.object({
    ruleId: RuleId,
    ruleName: RuleName,
    ruleLevel: RuleLevel,
    entity: EntityRef.optional(),
    attribute: AttributePath.optional(),
    message: z.string(),
}).strict()
export type RuleViolation = z.infer<typeof RuleViolation>
