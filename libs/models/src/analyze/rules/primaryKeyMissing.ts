import {Entity, EntityId, Relation} from "../../database";
import {entityToId, entityToRef} from "../../databaseUtils";
import {Rule, RuleViolation, RuleViolationLevel} from "../rule";

/**
 * Primary Keys are the default unique way to get a single row in a table.
 * They are also often used on foreign keys to reference a single record.
 * Having a primary key on every table is a common best practice.
 */

const ruleId = 'primary-key-missing'

export const primaryKeyMissing: Rule = {
    id: ruleId,
    name: 'Missing Primary Key',
    analyze(entities: Record<EntityId, Entity>, relations: Record<EntityId, Relation[]>): RuleViolation[] {
        return Object.values(entities).filter(isPrimaryKeysMissing).map(e => ({
            ruleId,
            entity: entityToRef(e),
            level: RuleViolationLevel.enum.medium,
            message: `Entity ${entityToId(e)} has no primary key.`
        }))
    }
}

// same as frontend/src/PagesComponents/Organization_/Project_/Views/Modals/SchemaAnalysis/PrimaryKeyMissing.elm
export function isPrimaryKeysMissing(entity: Entity): boolean {
    return !entity.pk && (entity.kind === undefined || entity.kind === 'table')
}
