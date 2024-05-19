import {describe, expect, test} from "@jest/globals";
import {Attribute, Database, Entity} from "../../database";
import {entityTooLargeRule, isEntityTooLarge} from "./entityTooLarge";
import {ruleConf} from "../rule.test";

describe('entityTooLarge', () => {
    test('valid entity', () => {
        const users: Entity = {name: 'users', attrs: [{name: 'id', type: 'uuid'}, {name: 'name', type: 'varcahr'}], pk: {attrs: [['id']]}}
        expect(isEntityTooLarge(users, 30)).toEqual(false)
    })
    test('invalid entity', () => {
        const users: Entity = {name: 'users', attrs: [{name: 'id', type: 'uuid'}, {name: 'name', type: 'varcahr'}], pk: {attrs: [['id']]}}
        expect(isEntityTooLarge(users, 1)).toEqual(true)
    })
    test('violation message', () => {
        const attrs: Attribute[] = [...new Array(40)].map((a, i) => ({name: `a${i}`, type: 'varchar'}))
        const db: Database = {entities: [{name: 'users', attrs: [{name: 'id', type: 'uuid'}, ...attrs]}]}
        expect(entityTooLargeRule.analyze({...ruleConf, max: 30}, db, []).map(v => v.message)).toEqual([
            'Entity users has too many attributes (41).'
        ])
    })
})
