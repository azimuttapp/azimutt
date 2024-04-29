import {Database} from "../database";
import {Rule, RuleViolation} from "./rule";
import {attributeTypeInconsistentRule} from "./rules/attributeTypeInconsistent";
import {entityNoIndexRule} from "./rules/entityNoIndex";
import {entityTooLargeRule} from "./rules/entityTooLarge";
import {indexDuplicatedRule} from "./rules/indexDuplicated";
import {indexOnRelationRule} from "./rules/indexOnRelation";
import {namingConsistencyRule} from "./rules/namingConsistency";
import {primaryKeyMissingRule} from "./rules/primaryKeyMissing";
import {primaryKeyNotBusinessRule} from "./rules/primaryKeyNotBusiness";
import {relationMisalignedRule} from "./rules/relationMisaligned";
import {relationMissAttributeRule} from "./rules/relationMissAttribute";
import {relationMissEntityRule} from "./rules/relationMissEntity";
import {relationMissingRule} from "./rules/relationMissing";

export * from "./rule"
export const analyzeRules: Rule[] = [
    attributeTypeInconsistentRule,
    entityNoIndexRule,
    entityTooLargeRule,
    indexDuplicatedRule,
    indexOnRelationRule,
    namingConsistencyRule,
    primaryKeyMissingRule,
    primaryKeyNotBusinessRule,
    relationMisalignedRule,
    relationMissAttributeRule,
    relationMissEntityRule,
    relationMissingRule,
]

export function analyzeDatabase(db: Database, ruleNames: string[]): RuleViolation[] {
    // TODO: tables with too many indexes
    // TODO: tables with too heavy indexes
    // TODO: unused index
    // TODO: unused table
    // TODO: slow queries
    // TODO: queries not using indexes
    // TODO: JSON columns with different schemas
    // TODO: sequence/auto_increment exhaustion
    // TODO: use varchar over char (https://youtu.be/ifEpT5STEU0?si=fcLBuwrgluG9crwt&t=90)
    // TODO: use uuid or bigint pk, not int or varchar ones
    const rules = ruleNames.length > 0 ? analyzeRules.filter(r => ruleNames.indexOf(r.id) !== -1 || ruleNames.indexOf(r.name) !== -1) : analyzeRules
    return rules.flatMap(r => r.analyze(db))
}
