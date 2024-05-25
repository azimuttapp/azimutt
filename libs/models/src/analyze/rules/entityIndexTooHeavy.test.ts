import {describe, expect, test} from "@jest/globals";
import {Database, Entity} from "../../database";
import {entityIndexTooHeavyRule, hasTooHeavyIndexes} from "./entityIndexTooHeavy";
import {ruleConf} from "../rule.test";

describe('entityIndexTooHeavy', () => {
    const now = Date.now()
    test('valid entity', () => {
        const users: Entity = {name: 'users', attrs: [], stats: {size: 1000, sizeIdx: 100}}
        expect(hasTooHeavyIndexes(users, 1)).toEqual(false)
    })
    test('invalid entity', () => {
        const users: Entity = {name: 'users', attrs: [], stats: {size: 100, sizeIdx: 1000}}
        expect(hasTooHeavyIndexes(users, 1)).toEqual(true)
    })
    test('violation message', () => {
        const db: Database = {entities: [{name: 'users', attrs: [{name: 'id', type: 'uuid'}], stats: {size: 100, sizeIdx: 1000}}]}
        expect(entityIndexTooHeavyRule.analyze({...ruleConf, ratio: 1}, now, db, [], []).map(v => v.message)).toEqual([
            'Entity users has too heavy indexes (10x data size).'
        ])
    })
    test('ignores', () => {
        const db: Database = {entities: [
            {name: 'users', attrs: [{name: 'id', type: 'uuid'}], stats: {size: 100, sizeIdx: 1000}},
            {name: 'posts', attrs: [{name: 'id', type: 'uuid'}], stats: {size: 100, sizeIdx: 200}},
        ]}
        expect(entityIndexTooHeavyRule.analyze({...ruleConf, ratio: 1}, now, db, [], []).map(v => v.message)).toEqual([
            'Entity users has too heavy indexes (10x data size).',
            'Entity posts has too heavy indexes (2x data size).',
        ])
        expect(entityIndexTooHeavyRule.analyze({...ruleConf, ratio: 1, ignores: ['posts']}, now, db, [], []).map(v => v.message)).toEqual([
            'Entity users has too heavy indexes (10x data size).',
        ])
    })
})
