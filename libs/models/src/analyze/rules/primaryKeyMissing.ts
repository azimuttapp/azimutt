import {Database, Entity} from "../../database";
import {entityToId, entityToRef} from "../../databaseUtils";
import {Rule, RuleId, RuleLevel, RuleName, RuleViolation} from "../rule";

/**
 * Primary Keys are the default unique way to get a single row in a table.
 * They are also often used on foreign keys to reference a single record.
 * Having a primary key on every table is a common best practice.
 */

const ruleId: RuleId = 'primary-key-missing'
const ruleName: RuleName = 'missing primary key'
const ruleLevel: RuleLevel = RuleLevel.enum.medium
export const primaryKeyMissingRule: Rule = {
    id: ruleId,
    name: ruleName,
    level: ruleLevel,
    analyze(db: Database): RuleViolation[] {
        return (db.entities || []).filter(isPrimaryKeysMissing).map(e => ({
            ruleId,
            ruleName,
            ruleLevel,
            entity: entityToRef(e),
            message: `Entity ${entityToId(e)} has no primary key.`
        }))
    }
}

// same as frontend/src/PagesComponents/Organization_/Project_/Views/Modals/SchemaAnalysis/PrimaryKeyMissing.elm
export function isPrimaryKeysMissing(entity: Entity): boolean {
    return !entity.pk && (entity.kind === undefined || entity.kind === 'table')
}
