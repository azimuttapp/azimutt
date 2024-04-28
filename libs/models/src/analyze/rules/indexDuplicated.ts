import {Database, Entity, Index} from "../../database";
import {attributePathToId, entityAttributesToId, entityToRef} from "../../databaseUtils";
import {Rule, RuleId, RuleLevel, RuleName, RuleViolation} from "../rule";

/**
 * Indexes are great to speed read performances, but they come at the cost of reducing write performances.
 * This is call write amplification, where writing a single row MUST update one or several indexes.
 * Most of the time this is not an issue because we read much more than we write, but still, only useful indexes should be kept.
 * This rule identify duplicated indexes, meaning they are redundant and the smallest one could be removed to speed writes without impacting reads.
 */

const ruleId: RuleId = 'index-duplicated'
const ruleName: RuleName = 'duplicated index'
const ruleLevel: RuleLevel = RuleLevel.enum.high
export const indexDuplicatedRule: Rule = {
    id: ruleId,
    name: ruleName,
    level: ruleLevel,
    analyze(db: Database): RuleViolation[] {
        return (db.entities || []).flatMap(getDuplicatedIndexes).map(i => ({
            ruleId,
            ruleName,
            ruleLevel,
            entity: entityToRef(i.entity),
            message: `Index ${indexName(i.entity, i.index)} can be deleted because it's covered by indexes: ${i.coveredBy.map(by => indexName(i.entity, by)).join(', ')}.`
        }))
    }
}

const indexName = (e: Entity, index: Index): string => index.name || `on ${entityAttributesToId(entityToRef(e), index.attrs)}`

export type IndexDuplicated = {entity: Entity, index: Index, coveredBy: Index[]}

// same as frontend/src/PagesComponents/Organization_/Project_/Views/Modals/SchemaAnalysis/IndexDuplicated.elm
export function getDuplicatedIndexes(entity: Entity): IndexDuplicated[] {
    return findDuplicated(entity, (entity.indexes || []).slice().sort((a, b) => (a.attrs.length - b.attrs.length) || (a.attrs.join(',').localeCompare(b.attrs.join(',')))))
}

function findDuplicated(entity: Entity, indexes: Index[], duplicates: IndexDuplicated[] = []): IndexDuplicated[] {
    const [index, ...tail] = indexes
    if (tail.length > 0) {
        const indexAttrs = index.attrs.map(attributePathToId)
        const coveredBy = tail.filter(index => indexAttrs.every((a, i) => a === attributePathToId(index.attrs[i])))
        if (coveredBy.length > 0) {
            return findDuplicated(entity, tail, duplicates.concat([{entity, index, coveredBy}]))
        } else {
            return findDuplicated(entity, tail, duplicates)
        }
    } else {
        return duplicates
    }
}
