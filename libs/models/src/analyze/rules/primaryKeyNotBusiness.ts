import {z} from "zod";
import {groupBy} from "@azimutt/utils";
import {Timestamp} from "../../common";
import {AttributesId, AttributesRef, Database, Entity, Relation} from "../../database";
import {
    attributePathToId,
    attributesRefFromId,
    attributesRefSame,
    entityRefToId,
    entityToId,
    entityToRef
} from "../../databaseUtils";
import {DatabaseQuery} from "../../interfaces/connector";
import {AnalyzeHistory, Rule, RuleConf, RuleId, RuleLevel, RuleName, RuleViolation} from "../rule";

/**
 * Primary Keys are the default unique way to get a single row in a table.
 * They are also often used on foreign keys to reference a single record.
 * Having a primary key on every table is a common best practice.
 */

const ruleId: RuleId = 'primary-key-not-business'
const ruleName: RuleName = 'business primary key forbidden'
const CustomRuleConf = RuleConf.extend({
    ignores: AttributesId.array().optional()
}).strict().describe('PrimaryKeyNotBusinessConf')
type CustomRuleConf = z.infer<typeof CustomRuleConf>
export const primaryKeyNotBusinessRule: Rule<CustomRuleConf> = {
    id: ruleId,
    name: ruleName,
    conf: {level: RuleLevel.enum.medium},
    zConf: CustomRuleConf,
    analyze(conf: CustomRuleConf, now: Timestamp, db: Database, queries: DatabaseQuery[], history: AnalyzeHistory[]): RuleViolation[] {
        const relations = groupBy(db.relations || [], r => entityRefToId(r.src))
        const ignores: AttributesRef[] = conf.ignores?.map(attributesRefFromId) || []
        return (db.entities || [])
            .filter(e => !isPrimaryKeyTechnical(e, relations[entityToId(e)] || []))
            .filter(e => !ignores.some(i => attributesRefSame(i, {...entityToRef(e), attributes: e.pk?.attrs || []})))
            .map(e => {
                const {stats, extra, ...primaryKey} = e.pk || {}
                return {
                    ruleId,
                    ruleName,
                    ruleLevel: conf.level,
                    message: `Entity ${entityToId(e)} should have a technical primary key, current one is: (${e.pk?.attrs.map(attributePathToId).join(', ')}).`,
                    entity: entityToRef(e),
                    attribute: e.pk?.attrs?.[0],
                    extra: {primaryKey}
                }
            })
    }
}

export function isPrimaryKeyTechnical(entity: Entity, relations: Relation[]): boolean {
    if ((entity.kind === undefined || entity.kind === 'table') && !!entity.pk) {
        // primary key attributes should either end with 'id' or have a relation, otherwise it's likely business
        return entity.pk.attrs.every(pkAttr => {
            const endsWithId = pkAttr.slice(-1)[0].toLowerCase().endsWith('id')
            const hasRelation = relations.find(r => r.attrs.find(a => attributePathToId(a.src) === attributePathToId(pkAttr)))
            return endsWithId || hasRelation
        })
    } else {
        return true // not table or no primary key
    }
}
