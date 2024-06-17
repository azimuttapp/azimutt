import {z} from "zod";
import {isNotUndefined, stringIsFloat, stringIsInt, stringIsISODate, stringIsUuid} from "@azimutt/utils";
import {Timestamp} from "../../common";
import {
    Attribute,
    AttributeId,
    AttributeRef,
    AttributeType,
    AttributeTypeKind,
    AttributeTypeParsed,
    AttributeValue,
    Database,
    Entity
} from "../../database";
import {
    attributeRefFromId,
    attributeRefSame,
    attributeRefToEntity,
    attributeRefToId,
    attributeTypeParse,
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

const ruleId: RuleId = 'attribute-type-bad'
const ruleName: RuleName = 'bad attribute type'
const CustomRuleConf = RuleConf.extend({
    ignores: AttributeId.array().optional()
}).strict().describe('AttributeTypeBadConf')
type CustomRuleConf = z.infer<typeof CustomRuleConf>
export const attributeTypeBadRule: Rule<CustomRuleConf> = {
    id: ruleId,
    name: ruleName,
    conf: {level: RuleLevel.enum.medium},
    zConf: CustomRuleConf,
    analyze(conf: CustomRuleConf, now: Timestamp, db: Database, queries: DatabaseQuery[], history: AnalyzeHistory[], reference: AnalyzeReportViolation[]): RuleViolation[] {
        const refIgnores: AttributeRef[] = reference.map(r => r.entity && r.attribute ? {...r.entity, attribute: r.attribute} : undefined).filter(isNotUndefined)
        const ignores: AttributeRef[] = refIgnores.concat(conf.ignores?.map(attributeRefFromId) || [])
        return (db.entities || [])
            .flatMap(getAttributesWithBadType)
            .filter(r => !ignores.some(i => attributeRefSame(i, r.ref)))
            .map(r => ({
                ruleId,
                ruleName,
                ruleLevel: conf.level,
                message: `Attribute ${attributeRefToId(r.ref)} with type ${r.type} could have type ${r.suggestion}.`,
                entity: attributeRefToEntity(r.ref),
                attribute: r.ref.attribute,
                extra: {attribute: r.ref, currentType: r.type, suggestedType: r.suggestion, sampleValues: r.values.slice(0, 10)}
            }))
    }
}

export function getAttributesWithBadType(entity: Entity): {ref: AttributeRef, type: AttributeType, suggestion: AttributeType, values: string[]}[] {
    return entity.attrs.map(a => {
        const suggestion = suggestedAttributeType(a)
        return suggestion ? {ref: {...entityToRef(entity), attribute: [a.name]}, type: a.type, ...suggestion} : undefined
    }).filter(isNotUndefined)
}

export function suggestedAttributeType(a: Attribute): {suggestion: AttributeType, values: string[]} | undefined {
    const type: AttributeTypeParsed = attributeTypeParse(a.type)
    const values: string[] = [
        ...a.stats?.commonValues?.map(v => v.value) || [],
        ...a.stats?.histogram || [],
        ...a.stats?.distinctValues || [],
    ].filter((v: AttributeValue): v is string => typeof v === 'string')
    if (type.kind === AttributeTypeKind.enum.string && values.length > 0) {
        if (values.every(stringIsISODate)) return {suggestion: 'timestamp', values: values}
        if (values.every(stringIsUuid)) return {suggestion: 'uuid', values: values}
        if (values.every(stringIsInt)) return {suggestion: 'int', values: values}
        if (values.every(stringIsFloat)) return {suggestion: 'decimal', values: values}
    }
    return undefined
}
