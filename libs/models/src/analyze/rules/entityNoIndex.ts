import {Database, Entity} from "../../database";
import {entityToId, entityToRef} from "../../databaseUtils";
import {Rule, RuleId, RuleLevel, RuleName, RuleViolation} from "../rule";

const ruleId: RuleId = 'entity-no-index'
const ruleName: RuleName = 'entity no index'
const ruleLevel: RuleLevel = RuleLevel.enum.high
export const entityNoIndexRule: Rule = {
    id: ruleId,
    name: ruleName,
    level: ruleLevel,
    analyze(db: Database): RuleViolation[] {
        return (db.entities || []).filter(hasEntityNoIndex).map(e => ({
            ruleId,
            ruleName,
            ruleLevel,
            entity: entityToRef(e),
            message: `Entity ${entityToId(e)} has no index.`
        }))
    }
}

// same as frontend/src/PagesComponents/Organization_/Project_/Views/Modals/SchemaAnalysis/TableWithoutIndex.elm
export function hasEntityNoIndex(entity: Entity): boolean {
    return entity.pk === undefined && (entity.indexes || []).length === 0
}
