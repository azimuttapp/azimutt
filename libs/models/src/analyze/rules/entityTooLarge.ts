import {Database, Entity} from "../../database";
import {entityToId, entityToRef} from "../../databaseUtils";
import {Rule, RuleId, RuleLevel, RuleName, RuleViolation} from "../rule";

const ruleId: RuleId = 'entity-too-large'
const ruleName: RuleName = 'entity too large'
const ruleLevel: RuleLevel = RuleLevel.enum.medium
export const entityTooLargeRule: Rule = {
    id: ruleId,
    name: ruleName,
    level: ruleLevel,
    analyze(db: Database): RuleViolation[] {
        return (db.entities || []).filter(isEntityTooLarge).map(e => ({
            ruleId,
            ruleName,
            ruleLevel,
            entity: entityToRef(e),
            message: `Entity ${entityToId(e)} has too many attributes (${e.attrs.length}).`
        }))
    }
}

// same as frontend/src/PagesComponents/Organization_/Project_/Views/Modals/SchemaAnalysis/TableTooBig.elm
export function isEntityTooLarge(entity: Entity): boolean {
    return entity.attrs.length > 30
}
