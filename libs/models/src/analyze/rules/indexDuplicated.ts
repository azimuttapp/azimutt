import {Entity, Index} from "../../database";
import {attributePathToId} from "../../databaseUtils";

/**
 * Indexes are great to speed read performances, but they come at the cost of reducing write performances.
 * This is call write amplification, where writing a single row MUST update one or several indexes.
 * Most of the time this is not an issue because we read much more than we write, but still, only useful indexes should be kept.
 * This rule identify duplicated indexes, meaning they are redundant and the smallest one could be removed to speed writes without impacting reads.
 */

export type IndexDuplicated = {entity: Entity, index: Index, coveredBy: Index[]}

// same as frontend/src/PagesComponents/Organization_/Project_/Views/Modals/SchemaAnalysis/IndexDuplicated.elm
export function getDuplicatedIndexes(entity: Entity): IndexDuplicated[] {
    return findDuplicated(entity, (entity.indexes || []).slice().sort((a, b) => (a.attrs.length - b.attrs.length) || (a.attrs.join(',').localeCompare(b.attrs.join(',')))))
}

function findDuplicated(entity: Entity, indexes: Index[], duplicates: IndexDuplicated[] = []): IndexDuplicated[] {
    const [index, ...tail] = indexes
    if (tail.length > 0) {
        const indexAttrs = index.attrs.map(attributePathToId).join(',')
        const coveredBy = tail.filter(i => i.attrs.map(attributePathToId).join(',').startsWith(indexAttrs))
        if (coveredBy.length > 0) {
            return findDuplicated(entity, tail, duplicates.concat([{entity, index, coveredBy}]))
        } else {
            return findDuplicated(entity, tail, duplicates)
        }
    } else {
        return duplicates
    }
}
