import {describe, expect, test} from "@jest/globals";
import {Database, Entity} from "../../database";
import {entityIndexNoneRule, hasNoIndex} from "./entityIndexNone";
import {ruleConf} from "../rule.test";

describe('entityIndexNone', () => {
    const now = Date.now()
    test('entity with primary key', () => {
        const users: Entity = {name: 'users', attrs: [{name: 'id', type: 'uuid'}], pk: {attrs: [['id']]}}
        expect(hasNoIndex(users)).toEqual(false)
    })
    test('entity with index', () => {
        const users: Entity = {name: 'users', attrs: [{name: 'id', type: 'uuid'}], indexes: [{attrs: [['id']]}]}
        expect(hasNoIndex(users)).toEqual(false)
    })
    test('invalid entity', () => {
        const users: Entity = {name: 'users', attrs: [{name: 'id', type: 'uuid'}]}
        expect(hasNoIndex(users)).toEqual(true)
    })
    test('violation message', () => {
        const db: Database = {entities: [{name: 'users', attrs: [{name: 'id', type: 'uuid'}]}]}
        expect(entityIndexNoneRule.analyze(ruleConf, now, db, [], [], []).map(v => v.message)).toEqual([
            'Entity users has no index.'
        ])
    })
    test('ignores', () => {
        const db: Database = {entities: [{name: 'users', attrs: [{name: 'id', type: 'uuid'}]}, {name: 'posts', attrs: [{name: 'id', type: 'uuid'}]}]}
        expect(entityIndexNoneRule.analyze(ruleConf, now, db, [], [], []).map(v => v.message)).toEqual([
            'Entity users has no index.',
            'Entity posts has no index.',
        ])
        expect(entityIndexNoneRule.analyze({...ruleConf, ignores: ['posts']}, now, db, [], [], []).map(v => v.message)).toEqual([
            'Entity users has no index.',
        ])
        expect(entityIndexNoneRule.analyze(ruleConf, now, db, [], [], [{message: '', entity: {entity: 'posts'}}]).map(v => v.message)).toEqual([
            'Entity users has no index.',
        ])
    })
})
