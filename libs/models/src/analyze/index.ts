import {Database} from "../database";
import {Rule, RuleViolation} from "./rule";
import {attributeTypeInconsistentRule} from "./rules/attributeTypeInconsistent";
import {entityNoIndexRule} from "./rules/entityNoIndex";
import {entityTooLargeRule} from "./rules/entityTooLarge";
import {indexDuplicatedRule} from "./rules/indexDuplicated";
import {indexOnRelationRule} from "./rules/indexOnRelation";
import {namingConsistencyRule} from "./rules/namingConsistency";
import {primaryKeyMissingRule} from "./rules/primaryKeyMissing";
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
    relationMisalignedRule,
    relationMissAttributeRule,
    relationMissEntityRule,
    relationMissingRule,
]

export function analyzeDatabase(db: Database): RuleViolation[] {
    // TODO: tables with too many indexes
    // TODO: tables with too heavy indexes
    // TODO: unused index
    // TODO: unused table
    // TODO: slow queries
    // TODO: queries not using indexes
    // TODO: JSON columns with different schemas
    // TODO: sequence/auto_increment exhaustion
    // TODO: no business primary key, no composite primary key
    return analyzeRules.flatMap(r => r.analyze(db))
}
