import {Entity, EntityId, EntityRef, Relation} from "../database";
import {z} from "zod";

export interface Rule {
    id: RuleId
    name: string
    analyze(entities: Record<EntityId, Entity>, relations: Record<EntityId, Relation[]>): RuleViolation[]
    // visitor pattern?
    // onDatabase(db: Database): RuleViolation[]
    // onEntity(entity: Entity): RuleViolation[]
    // onRelation(relation: Relation): RuleViolation[]
}

export const RuleId = z.string()
export type RuleId = z.infer<typeof RuleId>
export const RuleViolationLevel = z.enum(['high', 'medium', 'low', 'hint'])
export type RuleViolationLevel = z.infer<typeof RuleViolationLevel>
export const RuleViolation = z.object({
    ruleId: RuleId,
    entity: EntityRef.optional(),
    level: RuleViolationLevel,
    message: z.string(),
}).partial().strict()
export type RuleViolation = z.infer<typeof RuleViolation>
