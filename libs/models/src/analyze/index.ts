import {z} from "zod";
import {groupBy} from "@azimutt/utils";
import {Timestamp} from "../common";
import {zodParse} from "../zod";
import {Database, EntityId} from "../database";
import {entityRefToId} from "../databaseUtils";
import {ConnectorSchemaDataOpts, ConnectorScopeOpts, DatabaseQuery} from "../interfaces/connector";
import {AnalyzeHistory, Rule, RuleConf, RuleId, RuleLevel, RuleViolation} from "./rule";
import {attributeEmptyRule} from "./rules/attributeEmpty";
import {attributeNameInconsistentRule} from "./rules/attributeNameInconsistent";
import {attributeTypeBadRule} from "./rules/attributeTypeBad";
import {attributeTypeInconsistentRule} from "./rules/attributeTypeInconsistent";
import {entityEmptyRule} from "./rules/entityEmpty";
import {entityGrowFastRule} from "./rules/entityGrowFast";
import {entityIndexNoneRule} from "./rules/entityIndexNone";
import {entityIndexTooHeavyRule} from "./rules/entityIndexTooHeavy";
import {entityIndexTooManyRule} from "./rules/entityIndexTooMany";
import {entityNameInconsistentRule} from "./rules/entityNameInconsistent";
import {entityNotCleanRule} from "./rules/entityNotClean";
import {entityTooLargeRule} from "./rules/entityTooLarge";
import {entityUnusedRule} from "./rules/entityUnused";
import {indexDuplicatedRule} from "./rules/indexDuplicated";
import {indexGrowFastRule} from "./rules/indexGrowFast";
import {indexOnRelationRule} from "./rules/indexOnRelation";
import {indexUnusedRule} from "./rules/indexUnused";
import {primaryKeyMissingRule} from "./rules/primaryKeyMissing";
import {primaryKeyNotBusinessRule} from "./rules/primaryKeyNotBusiness";
import {queryDegradingRule} from "./rules/queryDegrading";
import {queryExpensiveRule} from "./rules/queryExpensive";
import {queryHighVariationRule} from "./rules/queryHighVariation";
import {queryTooSlowRule} from "./rules/queryTooSlow";
import {relationMisalignedRule} from "./rules/relationMisaligned";
import {relationMissAttributeRule} from "./rules/relationMissAttribute";
import {relationMissEntityRule} from "./rules/relationMissEntity";
import {relationMissingRule} from "./rules/relationMissing";

export * from "./rule"
export const analyzeRules: Rule[] = [
    // hint rules
    attributeTypeInconsistentRule,
    queryExpensiveRule,
    queryHighVariationRule,
    // low rules
    entityEmptyRule,
    attributeEmptyRule,
    entityNameInconsistentRule,
    attributeNameInconsistentRule,
    // medium rules
    entityUnusedRule,
    indexUnusedRule,
    attributeTypeBadRule,
    entityGrowFastRule,
    indexGrowFastRule,
    entityTooLargeRule,
    entityIndexTooManyRule,
    entityIndexTooHeavyRule,
    primaryKeyNotBusinessRule,
    indexOnRelationRule,
    relationMissingRule,
    // high rules
    indexDuplicatedRule,
    queryTooSlowRule,
    queryDegradingRule,
    entityNotCleanRule,
    primaryKeyMissingRule,
    entityIndexNoneRule,
    relationMisalignedRule,
    relationMissAttributeRule,
    relationMissEntityRule,
]

export const RulesConf = z.object({
    database: ConnectorScopeOpts.merge(ConnectorSchemaDataOpts).optional(),
    rules: z.object(Object.fromEntries(analyzeRules.map(r => [r.id, r.zConf.optional()]))).optional(),
}).strict().describe('RulesConf')
export type RulesConf = z.infer<typeof RulesConf>

export type RuleAnalyzed = {rule: Rule, conf: RuleConf, violations: RuleViolation[]}

// TODO: split rules by kind? (schema, query, data...)
export function analyzeDatabase(conf: RulesConf, now: Timestamp, db: Database, queries: DatabaseQuery[], history: AnalyzeHistory[], ruleNames: string[]): Record<RuleId, RuleAnalyzed> {
    // TODO: use uuid or bigint for single primary key, not int or varchar ones
    // TODO: uuids not stored as CHAR(36) => field ending with `id` and with type CHAR(36) => suggest type `uuid`/`BINARY(16)` instead (depend on db)
    // TODO: warn on queries with ORDER BY RAND()

    // TODO: constraints should be deferrable (pk, fk, unique)
    // TODO: tables/columns with incrementing names
    // TODO: columns with no (or very few) null but no NOT NULL constraint => suggest add NOT NULL constraint
    // TODO: columns with all (or mostly) different values but no UNIQUE constraint => suggest to add UNIQUE constraint
    // TODO: queries not using indexes
    // TODO: JSON columns with different schemas (% of similarity between schemas)
    // TODO: sequence/auto_increment exhaustion
    // TODO: use varchar over char (https://youtu.be/ifEpT5STEU0?si=fcLBuwrgluG9crwt&t=90)
    // TODO: auto_explain: index creation (https://pganalyze.com/docs/explain/setup/self_managed/01_auto_explain_check)
    const rules = ruleNames.length > 0 ? analyzeRules.filter(r => ruleNames.indexOf(r.id) !== -1 || ruleNames.indexOf(r.name) !== -1) : analyzeRules
    return Object.fromEntries(rules.map(r => {
        const ruleConf = Object.assign({}, r.conf, conf.rules?.[r.id])
        return [r.id, zodParse(r.zConf, r.id)(ruleConf).fold(
            ruleConf => ({rule: r, conf: ruleConf, violations: ruleConf.level === RuleLevel.enum.off ? [] : r.analyze(ruleConf, now, db, queries, history)}),
            err => ({rule: r, conf: ruleConf, violations: [{ruleId: r.id, ruleName: r.name, ruleLevel: r.conf.level, message: `Invalid conf: ${err}`}]})
        )]
    }))
}

// interesting:
// - most used tables (in queries)
// - table growth rate (Go/Month)
// - query slow down rate (ms/month, mean & max)
// - unused tables / indexes

export function scoreDatabase(db: Database, violations: RuleViolation[]): {score: number, entities: Record<EntityId, number>} {
    // TODO: compute table importance: page rank & data cardinality (other interesting inputs: storage size, nb columns, nb relations, nb queries, nb indexes), use it to weight the overall score
    const violationsByEntity: Record<EntityId, RuleViolation[]> = groupBy(violations, v => v.entity ? entityRefToId(v.entity) : 'unknown')
    return {score: 0, entities: {}}
}

// safe migration rules:
// - always concurrently in create/drop indexes
// - disable validations at the beginning, enable them at the end (foreign keys, unique, pk, checks...)
// - no default value on add column (will update every row otherwise)
// - drop foreign keys before dropping a table
