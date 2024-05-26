import {describe, expect, test} from "@jest/globals";
import {Database, Entity} from "../../database";
import {entityEmptyRule, isEntityEmpty} from "./entityEmpty";
import {ruleConf} from "../rule.test";

describe('entityEmpty', () => {
    const now = Date.now()
    test('valid entity', () => {
        const users: Entity = {name: 'users', attrs: [], stats: {rows: 10}}
        const posts: Entity = {name: 'posts', attrs: [], stats: {size: 10}}
        const comments: Entity = {name: 'comments', attrs: []}
        expect(isEntityEmpty(posts)).toEqual(false)
        expect(isEntityEmpty(users)).toEqual(false)
        expect(isEntityEmpty(comments)).toEqual(false)
    })
    test('invalid entity', () => {
        const users: Entity = {name: 'users', attrs: [], stats: {rows: 0}}
        const posts: Entity = {name: 'posts', attrs: [], stats: {size: 0}}
        expect(isEntityEmpty(users)).toEqual(true)
        expect(isEntityEmpty(posts)).toEqual(true)
    })
    test('violation message', () => {
        const db: Database = {entities: [{name: 'users', attrs: [], stats: {rows: 0}}]}
        expect(entityEmptyRule.analyze(ruleConf, now, db, [], []).map(v => v.message)).toEqual([
            'Entity users is empty.'
        ])
    })
    test('ignores', () => {
        const db: Database = {entities: [
            {name: 'users', attrs: [], stats: {rows: 0}},
            {name: 'posts', attrs: [], stats: {rows: 0}},
        ]}
        expect(entityEmptyRule.analyze(ruleConf, now, db, [], []).map(v => v.message)).toEqual([
            'Entity users is empty.',
            'Entity posts is empty.',
        ])
        expect(entityEmptyRule.analyze({...ruleConf, ignores: ['posts']}, now, db, [], []).map(v => v.message)).toEqual([
            'Entity users is empty.',
        ])
    })
})
