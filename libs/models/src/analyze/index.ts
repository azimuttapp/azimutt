import {groupBy} from "@azimutt/utils";
import {Database, EntityId} from "../database";
import {entityRefToId} from "../databaseUtils";
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
    // TODO: tables with too many indexes (> 20)
    // TODO: tables with too heavy indexes (index storage > table storage)
    // TODO: unused index
    // TODO: unused table
    // TODO: queries not using indexes
    // TODO: JSON columns with different schemas (% of similarity between schemas)
    // TODO: sequence/auto_increment exhaustion
    // TODO: use varchar over char (https://youtu.be/ifEpT5STEU0?si=fcLBuwrgluG9crwt&t=90)
    // TODO: use uuid or bigint pk, not int or varchar ones
    // TODO: slow queries (mean exec time > 100ms, high sd, high total_exec_time) => exec plan, create indexes
    const rules = ruleNames.length > 0 ? analyzeRules.filter(r => ruleNames.indexOf(r.id) !== -1 || ruleNames.indexOf(r.name) !== -1) : analyzeRules
    return rules.flatMap(r => r.analyze(db))
}

export function scoreDatabase(db: Database, violations: RuleViolation[]): {score: number, entities: Record<EntityId, number>} {
    // TODO: compute table importance: page rank & data cardinality (other interesting inputs: storage size, nb columns, nb relations, nb queries, nb indexes), use it to weight the overall score
    const violationsByEntity: Record<EntityId, RuleViolation[]> = groupBy(violations, v => v.entity ? entityRefToId(v.entity) : 'unknown')
    return {score: 0, entities: {}}
}
