import {describe, expect, test} from "@jest/globals";
import {Attribute, Database, Entity} from "../../database";
import {entityTooLargeRule, isEntityTooLarge} from "./entityTooLarge";
import {ruleConf} from "../rule.test";

describe('entityTooLarge', () => {
    const now = Date.now()
    test('valid entity', () => {
        const users: Entity = {name: 'users', attrs: [{name: 'id', type: 'uuid'}, {name: 'name', type: 'varchar'}], pk: {attrs: [['id']]}}
        expect(isEntityTooLarge(users, 30)).toEqual(false)
    })
    test('invalid entity', () => {
        const users: Entity = {name: 'users', attrs: [{name: 'id', type: 'uuid'}, {name: 'name', type: 'varchar'}], pk: {attrs: [['id']]}}
        expect(isEntityTooLarge(users, 1)).toEqual(true)
    })
    test('violation message', () => {
        const attrs: Attribute[] = [...new Array(40)].map((a, i) => ({name: `a${i}`, type: 'varchar'}))
        const db: Database = {entities: [{name: 'users', attrs: [{name: 'id', type: 'uuid'}, ...attrs]}]}
        expect(entityTooLargeRule.analyze({...ruleConf, max: 30}, now, db, [], []).map(v => v.message)).toEqual([
            'Entity users has too many attributes (41).'
        ])
    })
    test('ignores', () => {
        const db: Database = {entities: [
            {name: 'users', attrs: [{name: 'id', type: 'uuid'}, {name: 'name', type: 'varchar'}, {name: 'email', type: 'varchar'}]},
            {name: 'posts', attrs: [{name: 'id', type: 'uuid'}, {name: 'title', type: 'varchar'}, {name: 'content', type: 'text'}, {name: 'tags', type: 'varchar[]'}]},
        ]}
        expect(entityTooLargeRule.analyze({...ruleConf, max: 2}, now, db, [], []).map(v => v.message)).toEqual([
            'Entity users has too many attributes (3).',
            'Entity posts has too many attributes (4).',
        ])
        expect(entityTooLargeRule.analyze({...ruleConf, max: 2, ignores: ['posts']}, now, db, [], []).map(v => v.message)).toEqual([
            'Entity users has too many attributes (3).',
        ])
    })
})
