import {z} from "zod";
import {groupBy, isNotUndefined, singular, splitWords} from "@azimutt/utils";
import {Timestamp} from "../../common";
import {
    AttributePath,
    AttributeValue,
    Database,
    Entity,
    EntityId,
    EntityRef,
    Relation,
    RelationId,
    RelationRef
} from "../../database";
import {
    attributePathToId,
    attributesRefToId,
    attributeValueToString,
    entityRefToId,
    entityToRef,
    flattenAttributes,
    getPeerAttributes,
    relationLinkToEntityRef,
    relationRefFromId,
    relationRefSame,
    relationToRef
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
 * If relations are not defined as foreign key, it could be great to identify them
 */

const ruleId: RuleId = 'relation-missing'
const ruleName: RuleName = 'missing relation'
const ruleDescription: string = 'relations not present in the database but could exist'
const CustomRuleConf = RuleConf.extend({
    ignores: RelationId.array().optional(),
}).strict().describe('RelationMissingConf')
type CustomRuleConf = z.infer<typeof CustomRuleConf>
export const relationMissingRule: Rule<CustomRuleConf> = {
    id: ruleId,
    name: ruleName,
    description: ruleDescription,
    conf: {level: RuleLevel.enum.medium},
    zConf: CustomRuleConf,
    analyze(conf: CustomRuleConf, now: Timestamp, db: Database, queries: DatabaseQuery[], history: AnalyzeHistory[], reference: AnalyzeReportViolation[]): RuleViolation[] {
        const refIgnores: RelationRef[] = reference.map(r => r.extra?.relation ? relationToRef(r.extra?.relation) : undefined).filter(isNotUndefined)
        const ignores: RelationRef[] = refIgnores.concat(conf.ignores?.map(relationRefFromId) || [])
        return getMissingRelations(db.entities || [], db.relations || [])
            .filter(r => !ignores.some(i => relationRefSame(i, relationToRef(r))))
            .map(r => ({
                ruleId,
                ruleName,
                ruleLevel: conf.level,
                message: `Create a relation from ${attributesRefToId({...r.src, attrs: r.src.attrs})} to ${attributesRefToId({...r.ref, attrs: r.ref.attrs})}.`,
                entity: relationLinkToEntityRef(r.src),
                attribute: r.src.attrs[0],
                extra: {relation: r}
            }))
    }
}

// same as frontend/src/PagesComponents/Organization_/Project_/Views/Modals/SchemaAnalysis/RelationMissing.elm
export function getMissingRelations(entities: Entity[], relations: Relation[]): Relation[] {
    const tableEntities = entities.filter(e => e.kind === undefined || e.kind === 'table') // don't suggest relation to a view
    const entitiesByName: Record<EntityNameNormalized, Entity[]> = groupBy(tableEntities, e => splitWords(e.name).map(singular).join('_'))
    const entitiesByPrefixName: Record<EntityNameNormalized, Entity[]> = groupBy(tableEntities.filter(e => splitWords(e.name).length > 1), e => splitWords(e.name).slice(1).map(singular).join('_'))
    const entitiesByPrefixName2: Record<EntityNameNormalized, Entity[]> = groupBy(tableEntities.filter(e => splitWords(e.name).length > 2), e => splitWords(e.name).slice(2).map(singular).join('_'))
    const relationsBySrc: Record<EntityId, Relation[]> = groupBy(relations, r => entityRefToId(r.src))

    return tableEntities.flatMap(entity => {
        return flattenAttributes(entity.attrs).flatMap(({path, ...attr}) => {
            const attrWords = splitWords(attr.name).map(singular)
            const lastWord = attrWords[attrWords.length - 1]
            let results: Relation[] = []
            if (lastWord === 'id' && attrWords.length > 1) {
                return guessAllRelationTargetsWithPoly(entitiesByName, entitiesByPrefixName, entitiesByPrefixName2, entity, path, attrWords)
            } else if (lastWord.endsWith('id') && lastWord.length > 2) {
                const words = [...attrWords.slice(0, -1), lastWord.slice(0, -2), lastWord.slice(-2)]
                return guessAllRelationTargetsWithPoly(entitiesByName, entitiesByPrefixName, entitiesByPrefixName2, entity, path, words)
            } else if (lastWord === 'by') {
                const entityRef: EntityRef = entityToRef(entity)
                let targets = guessRelationTargets(entitiesByName, entityRef, ['user', 'id'])
                targets = targets.length === 0 ? guessRelationTargets(entitiesByName, entityRef, ['account', 'id']) : targets
                results = targets.map(ref => ({src: {...entityRef, attrs: [path]}, ref: {...ref.entity, attrs: [ref.attr]}, origin: 'infer-name'}))
            }
            return results
        })
    }).filter(r => !loopingRelation(r)).filter(r => !relationAlreadyExist(relationsBySrc, r))
}

type EntityNameNormalized = string


function guessAllRelationTargetsWithPoly(
    entitiesByName: Record<EntityNameNormalized, Entity[]>,
    entitiesByPrefixName: Record<EntityNameNormalized, Entity[]>,
    entitiesByPrefixName2: Record<EntityNameNormalized, Entity[]>,
    entity: Entity,
    attrPath: AttributePath,
    attrWords: string[]
): Relation[] {
    const poly = getPolymorphicColumn(entity, attrPath)
    const entityRef = entityToRef(entity)
    if (poly) {
        return poly.values.flatMap(value => {
            const words = splitWords(attributeValueToString(value)).map(singular).concat(['id'])
            return guessRelationTargetsWithPrefixes(entitiesByName, entitiesByPrefixName, entitiesByPrefixName2, entityRef, attrPath, words)
                .map(r => ({...r, polymorphic: {attribute: poly.path, value}}))
        })
    } else {
        return guessRelationTargetsWithPrefixes(entitiesByName, entitiesByPrefixName, entitiesByPrefixName2, entityRef, attrPath, attrWords)
    }
}

function guessRelationTargetsWithPrefixes(
    entitiesByName: Record<EntityNameNormalized, Entity[]>,
    entitiesByPrefixName: Record<EntityNameNormalized, Entity[]>,
    entitiesByPrefixName2: Record<EntityNameNormalized, Entity[]>,
    entityRef: EntityRef,
    attrPath: AttributePath,
    attrWords: string[]
): Relation[] {
    let targets = guessRelationTargets(entitiesByName, entityRef, attrWords)
    targets = targets.length === 0 ? guessRelationTargets(entitiesByPrefixName, entityRef, attrWords) : targets
    targets = targets.length === 0 ? guessRelationTargets(entitiesByPrefixName2, entityRef, attrWords) : targets
    return targets.map(ref => ({src: {...entityRef, attrs: [attrPath]}, ref: {...ref.entity, attrs: [ref.attr]}, origin: 'infer-name'}))
}

function guessRelationTargets(entitiesByName: Record<EntityNameNormalized, Entity[]>, ref: EntityRef, attrWords: string[]): {entity: EntityRef, attr: AttributePath}[] {
    return (entitiesByName[attrWords.slice(0, -1).join('_')] || []).concat(
        entitiesByName[attrWords.slice(1, -1).join('_')] || [], // remove hypothetical prefixes (up to 3)
        entitiesByName[attrWords.slice(2, -1).join('_')] || [],
        entitiesByName[attrWords.slice(3, -1).join('_')] || [],
        entitiesByName[attrWords.slice(0, -2).join('_')] || [], // remove hypothetical suffixes (up to 3)
        entitiesByName[attrWords.slice(0, -3).join('_')] || [],
        entitiesByName[attrWords.slice(0, -4).join('_')] || [],
        entitiesByName[attrWords.slice(1, -2).join('_')] || [], // remove hypothetical prefixes & suffixes (up to 2)
        entitiesByName[attrWords.slice(2, -2).join('_')] || [],
        entitiesByName[attrWords.slice(1, -3).join('_')] || [],
        entitiesByName[attrWords.slice(2, -3).join('_')] || [],
    ).sort((a, b) => namespaceScore(a, ref) - namespaceScore(b, ref)).flatMap((entity: Entity) => {
        const attrName: string = attrWords.slice(-1)[0]
        const attr = entity.attrs?.find(a => a.name === attrName) || entity.attrs?.find(a => {
            const words = a.name.endsWith('id') ? splitWords(a.name.slice(0, -2)).concat(['id']) : splitWords(a.name)
            return words.join('_') === attrWords.slice(words.length * -1).join('_')
        })
        return attr ? [{entity: entityToRef(entity), attr: [attr.name]}] : []
    })
}

// lower is nearer
const namespaceScore = (e: Entity, ref: EntityRef): number => (e.schema !== ref.schema ? 1 : 0) + (e.catalog !== ref.catalog ? 10 : 0) + (e.database !== ref.database ? 100 : 0)

function getPolymorphicColumn(entity: Entity, attribute: AttributePath): {path: AttributePath, values: AttributeValue[]} | undefined {
    const suffixes = ['type', 'kind', 'class']
    const parent = attribute.slice(0, -1)
    const last = attribute[attribute.length - 1]
    const prefix = last.endsWith('ids') ? last.slice(0, -3) : (last.endsWith('id') ? last.slice(0, -2) : last)
    const attr = getPeerAttributes(entity.attrs, parent).find(a => suffixes.some(s => a.name.toLowerCase() === `${prefix}${s}`.toLowerCase()))
    return attr?.stats?.distinctValues ? {path: parent.concat([attr.name]), values: attr.stats.distinctValues} : undefined
}

function loopingRelation(r: Relation): boolean {
    return entityRefToId(r.src) === entityRefToId(r.ref) && r.src.attrs.map(attributePathToId).join(',') === r.ref.attrs.map(attributePathToId).join(',')
}

function relationAlreadyExist(relationsBySrc: Record<EntityId, Relation[]>, relation: Relation): boolean {
    const relationRefEntity = entityRefToId(relation.ref)
    const relationSrcAttrs = relation.src.attrs.map(attributePathToId).join(',')
    const relationRefAttrs = relation.ref.attrs.map(attributePathToId).join(',')
    const sameRelations = (relationsBySrc[entityRefToId(relation.src)] || []) // from same entity
        .filter(r => entityRefToId(r.ref) === relationRefEntity) // to same entity
        .filter(r => r.src.attrs.map(attributePathToId).join(',') === relationSrcAttrs) // from same attributes
        .filter(r => r.ref.attrs.map(attributePathToId).join(',') === relationRefAttrs) // to same attributes
    return sameRelations.length > 0
}
