import {describe, expect, test} from "@jest/globals";
import {Database, Entity} from "../../database";
import {isPrimaryKeysMissing, primaryKeyMissingRule} from "./primaryKeyMissing";
import {ruleConf} from "../rule.test";

describe('primaryKeyMissing', () => {
    test('valid entity', () => {
        const users: Entity = {name: 'users', attrs: [{name: 'id', type: 'uuid'}], pk: {attrs: [['id']]}}
        expect(isPrimaryKeysMissing(users)).toEqual(false)
    })
    test('missing primary key', () => {
        const users: Entity = {name: 'users', attrs: [{name: 'id', type: 'uuid'}]}
        expect(isPrimaryKeysMissing(users)).toEqual(true)
    })
    test('no missing primary key on views', () => {
        const users: Entity = {name: 'users', kind: 'view', attrs: [{name: 'id', type: 'uuid'}]}
        expect(isPrimaryKeysMissing(users)).toEqual(false)
    })
    test('ignores', () => {
        const db: Database = {entities: [
            {name: 'users', attrs: [{name: 'id', type: 'uuid'}]},
            {name: 'posts', attrs: [{name: 'id', type: 'uuid'}]},
        ]}
        expect(primaryKeyMissingRule.analyze(ruleConf, db, []).map(v => v.message)).toEqual([
            'Entity users has no primary key.',
            'Entity posts has no primary key.',
        ])
        expect(primaryKeyMissingRule.analyze({...ruleConf, ignores: ['posts']}, db, []).map(v => v.message)).toEqual([
            'Entity users has no primary key.',
        ])
    })
    test('violation message', () => {
        const db: Database = {entities: [{name: 'users', attrs: [{name: 'id', type: 'uuid'}]}]}
        expect(primaryKeyMissingRule.analyze(ruleConf, db, []).map(v => v.message)).toEqual([
            'Entity users has no primary key.'
        ])
    })
})
