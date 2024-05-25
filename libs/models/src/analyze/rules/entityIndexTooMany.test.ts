import {describe, expect, test} from "@jest/globals";
import {Database, Entity} from "../../database";
import {entityIndexTooManyRule, hasTooManyIndexes} from "./entityIndexTooMany";
import {ruleConf} from "../rule.test";

describe('entityIndexTooMany', () => {
    const now = Date.now()
    test('valid entity', () => {
        const users: Entity = {name: 'users', attrs: []}
        expect(hasTooManyIndexes(users, 20)).toEqual(false)
    })
    test('invalid entity', () => {
        const users: Entity = {name: 'users', attrs: [], indexes: [{attrs: [['id']]}, {attrs: [['name']]}, {attrs: [['email']]}]}
        expect(hasTooManyIndexes(users, 1)).toEqual(true)
    })
    test('violation message', () => {
        const db: Database = {entities: [{name: 'users', attrs: [{name: 'id', type: 'uuid'}, {name: 'name', type: 'varchar'}, {name: 'email', type: 'varchar'}], indexes: [{attrs: [['id']]}, {attrs: [['name']]}, {attrs: [['email']]}]}]}
        expect(entityIndexTooManyRule.analyze({...ruleConf, max: 2}, now, db, [], []).map(v => v.message)).toEqual([
            'Entity users has too many indexes (3).'
        ])
    })
    test('ignores', () => {
        const db: Database = {entities: [
            {name: 'users', attrs: [{name: 'id', type: 'uuid'}, {name: 'name', type: 'varchar'}, {name: 'email', type: 'varchar'}], indexes: [{attrs: [['id']]}, {attrs: [['name']]}, {attrs: [['email']]}]},
            {name: 'posts', attrs: [{name: 'id', type: 'uuid'}, {name: 'title', type: 'varchar'}, {name: 'content', type: 'text'}, {name: 'tags', type: 'varchar[]'}], indexes: [{attrs: [['id']]}, {attrs: [['title']]}]},
        ]}
        expect(entityIndexTooManyRule.analyze({...ruleConf, max: 1}, now, db, [], []).map(v => v.message)).toEqual([
            'Entity users has too many indexes (3).',
            'Entity posts has too many indexes (2).',
        ])
        expect(entityIndexTooManyRule.analyze({...ruleConf, max: 1, ignores: ['posts']}, now, db, [], []).map(v => v.message)).toEqual([
            'Entity users has too many indexes (3).',
        ])
    })
})
