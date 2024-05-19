import {z} from "zod";
import {groupBy} from "@azimutt/utils";
import {Database, Entity, Relation} from "../../database";
import {attributePathToId, entityRefToId, entityToId, entityToRef} from "../../databaseUtils";
import {DatabaseQuery} from "../../interfaces/connector";
import {Rule, RuleConf, RuleId, RuleLevel, RuleName, RuleViolation} from "../rule";

/**
 * Primary Keys are the default unique way to get a single row in a table.
 * They are also often used on foreign keys to reference a single record.
 * Having a primary key on every table is a common best practice.
 */

const ruleId: RuleId = 'primary-key-not-business'
const ruleName: RuleName = 'no business primary key'
const CustomRuleConf = RuleConf
type CustomRuleConf = z.infer<typeof CustomRuleConf>
export const primaryKeyNotBusinessRule: Rule<CustomRuleConf> = {
    id: ruleId,
    name: ruleName,
    conf: {level: RuleLevel.enum.medium},
    zConf: CustomRuleConf,
    analyze(conf: CustomRuleConf, db: Database, queries: DatabaseQuery[]): RuleViolation[] {
        const relations = groupBy(db.relations || [], r => entityRefToId(r.src))
        return (db.entities || []).filter(e => !isPrimaryKeyTechnical(e, relations[entityToId(e)] || [])).map(e => ({
            ruleId,
            ruleName,
            ruleLevel: conf.level,
            entity: entityToRef(e),
            message: `Entity ${entityToId(e)} should have a technical primary key, current one is: (${e.pk?.attrs.map(attributePathToId).join(', ')}).`
        }))
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
