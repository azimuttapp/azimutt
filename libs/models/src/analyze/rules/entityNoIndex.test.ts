import {describe, expect, test} from "@jest/globals";
import {Database, Entity} from "../../database";
import {entityNoIndexRule, hasEntityNoIndex} from "./entityNoIndex";
import {ruleConf} from "../rule.test";

describe('entityNoIndex', () => {
    test('entity with primary key', () => {
        const users: Entity = {name: 'users', attrs: [{name: 'id', type: 'uuid'}], pk: {attrs: [['id']]}}
        expect(hasEntityNoIndex(users)).toEqual(false)
    })
    test('entity with index', () => {
        const users: Entity = {name: 'users', attrs: [{name: 'id', type: 'uuid'}], indexes: [{attrs: [['id']]}]}
        expect(hasEntityNoIndex(users)).toEqual(false)
    })
    test('invalid entity', () => {
        const users: Entity = {name: 'users', attrs: [{name: 'id', type: 'uuid'}]}
        expect(hasEntityNoIndex(users)).toEqual(true)
    })
    test('ignores', () => {
        const db: Database = {entities: [{name: 'users', attrs: [{name: 'id', type: 'uuid'}]}, {name: 'posts', attrs: [{name: 'id', type: 'uuid'}]}]}
        expect(entityNoIndexRule.analyze(ruleConf, db, []).map(v => v.message)).toEqual([
            'Entity users has no index.',
            'Entity posts has no index.',
        ])
        expect(entityNoIndexRule.analyze({...ruleConf, ignores: ['posts']}, db, []).map(v => v.message)).toEqual([
            'Entity users has no index.',
        ])
    })
    test('violation message', () => {
        const db: Database = {entities: [{name: 'users', attrs: [{name: 'id', type: 'uuid'}]}]}
        expect(entityNoIndexRule.analyze(ruleConf, db, []).map(v => v.message)).toEqual([
            'Entity users has no index.'
        ])
    })
})
