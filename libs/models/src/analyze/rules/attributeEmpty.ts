import {z} from "zod";
import {isNotUndefined} from "@azimutt/utils";
import {Timestamp} from "../../common";
import {Attribute, AttributeId, AttributeRef, Database, Entity} from "../../database";
import {
    attributeRefFromId,
    attributeRefSame,
    attributeRefToEntity,
    attributeRefToId,
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

const ruleId: RuleId = 'attribute-empty'
const ruleName: RuleName = 'empty attribute'
const CustomRuleConf = RuleConf.extend({
    ignores: AttributeId.array().optional()
}).strict().describe('AttributeEmptyConf')
type CustomRuleConf = z.infer<typeof CustomRuleConf>
export const attributeEmptyRule: Rule<CustomRuleConf> = {
    id: ruleId,
    name: ruleName,
    conf: {level: RuleLevel.enum.low},
    zConf: CustomRuleConf,
    analyze(conf: CustomRuleConf, now: Timestamp, db: Database, queries: DatabaseQuery[], history: AnalyzeHistory[], reference: AnalyzeReportViolation[]): RuleViolation[] {
        const refIgnores: AttributeRef[] = reference.map(r => r.entity && r.attribute ? {...r.entity, attribute: r.attribute} : undefined).filter(isNotUndefined)
        const ignores: AttributeRef[] = refIgnores.concat(conf.ignores?.map(attributeRefFromId) || [])
        return (db.entities || [])
            .flatMap(getEmptyAttributes)
            .filter(r => !ignores.some(i => attributeRefSame(i, r)))
            .map(r => ({
                ruleId,
                ruleName,
                ruleLevel: conf.level,
                message: `Attribute ${attributeRefToId(r)} is empty.`,
                entity: attributeRefToEntity(r),
                attribute: r.attribute,
            }))
    }
}

export function getEmptyAttributes(entity: Entity): AttributeRef[] {
    return entity.attrs.filter(isAttributeEmpty).map(attribute => ({...entityToRef(entity), attribute: [attribute.name]}))
}

export function isAttributeEmpty(a: Attribute): boolean {
    return a.null === true && ((a.stats?.cardinality !== undefined ? a.stats.cardinality === 0 : false) || (a.stats?.nulls !== undefined ? a.stats.nulls === 1 : false))
}
