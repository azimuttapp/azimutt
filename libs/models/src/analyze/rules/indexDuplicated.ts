import {z} from "zod";
import {isNotUndefined} from "@azimutt/utils";
import {Timestamp} from "../../common";
import {AttributesId, AttributesRef, Database, Entity, Index} from "../../database";
import {
    attributePathToId,
    attributesRefFromId,
    attributesRefSame,
    attributesRefToId,
    entityToRef
} from "../../databaseUtils";
import {DatabaseQuery} from "../../interfaces/connector";
import {
    AnalyzeHistory,
    AnalyzeReportViolation,
    Rule,
    RuleConf,
    RuleId,
    RuleLevel,
    RuleName,
    RuleViolation
} from "../rule";

/**
 * Indexes are great to speed read performances, but they come at the cost of reducing write performances.
 * This is call write amplification, where writing a single row MUST update one or several indexes.
 * Most of the time this is not an issue because we read much more than we write, but still, only useful indexes should be kept.
 * This rule identify duplicated indexes, meaning they are redundant and the smallest one could be removed to speed writes without impacting reads.
 */

const ruleId: RuleId = 'index-duplicated'
const ruleName: RuleName = 'duplicated index'
const ruleDescription: string = 'indexes with all columns covered by other indexes'
const CustomRuleConf = RuleConf.extend({
    ignores: AttributesId.array().optional()
}).strict().describe('IndexDuplicatedConf')
type CustomRuleConf = z.infer<typeof CustomRuleConf>
export const indexDuplicatedRule: Rule<CustomRuleConf> = {
    id: ruleId,
    name: ruleName,
    description: ruleDescription,
    conf: {level: RuleLevel.enum.high},
    zConf: CustomRuleConf,
    analyze(conf: CustomRuleConf, now: Timestamp, db: Database, queries: DatabaseQuery[], history: AnalyzeHistory[], reference: AnalyzeReportViolation[]): RuleViolation[] {
        const refIgnores: AttributesRef[] = reference.map(r => r.entity && Array.isArray(r.extra?.index?.attrs) ? {...r.entity, attributes: r.extra.index.attrs} : undefined).filter(isNotUndefined)
        const ignores: AttributesRef[] = refIgnores.concat(conf.ignores?.map(attributesRefFromId) || [])
        return (db.entities || []).flatMap(getDuplicatedIndexes)
            .filter(idx => !ignores.some(i => attributesRefSame(i, {...entityToRef(idx.entity), attributes: idx.index.attrs})))
            .map(i => {
                const entity = entityToRef(i.entity)
                const indexName = `${i.index.name ? i.index.name + ' ' : ''}on ${attributesRefToId({...entity, attributes: i.index.attrs})}`
                const message = `Index ${indexName} can be deleted, it's covered by: ${i.coveredBy.map(by => `${by.name || ''}(${by.attrs.map(attributePathToId).join(', ')})`).join(', ')}.`
                const {stats, extra, ...index} = i.index
                const coveredBy = i.coveredBy.map(({stats, extra, ...index}) => index)
                return {ruleId, ruleName, ruleLevel: conf.level, message, entity, attribute: i.index.attrs[0], extra: {index, coveredBy}}
            })
    }
}

export type IndexDuplicated = {entity: Entity, index: Index, coveredBy: Index[]}

// same as frontend/src/PagesComponents/Organization_/Project_/Views/Modals/SchemaAnalysis/IndexDuplicated.elm
export function getDuplicatedIndexes(entity: Entity): IndexDuplicated[] {
    const indexes = (entity.indexes || [])
        .filter(i => !i.attrs.some(a => a[0] === 'unknown' || a[0] === '*expression*')) // ignore indexes with expressions
        .sort((a, b) => (a.attrs.length - b.attrs.length) || (a.attrs.join(',').localeCompare(b.attrs.join(','))))
    return findDuplicated(entity, indexes)
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
