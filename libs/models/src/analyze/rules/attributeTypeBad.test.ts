import {describe, expect, test} from "@jest/globals";
import {Database} from "../../database";
import {attributeTypeBadRule, suggestedAttributeType} from "./attributeTypeBad";
import {ruleConf} from "../rule.test";

describe('attributeTypeBad', () => {
    const now = Date.now()
    test('valid entity', () => {
        expect(suggestedAttributeType({name: 'name', type: 'text'})).toEqual(undefined)
        expect(suggestedAttributeType({name: 'name', type: 'text', stats: {distinctValues: []}})).toEqual(undefined)
        expect(suggestedAttributeType({name: 'name', type: 'text', stats: {distinctValues: ['test']}})).toEqual(undefined)
    })
    test('invalid entity', () => {
        expect(suggestedAttributeType({name: 'name', type: 'text', stats: {distinctValues: ['2024-05-30T09:49:58.068Z']}})).toEqual({suggestion: 'timestamp', values: ['2024-05-30T09:49:58.068Z']})
        expect(suggestedAttributeType({name: 'name', type: 'text', stats: {distinctValues: ['c4f39518-1e6c-11ef-9262-0242ac120002']}})).toEqual({suggestion: 'uuid', values: ['c4f39518-1e6c-11ef-9262-0242ac120002']})
        expect(suggestedAttributeType({name: 'name', type: 'text', stats: {distinctValues: ['12']}})).toEqual({suggestion: 'int', values: ['12']})
        expect(suggestedAttributeType({name: 'name', type: 'text', stats: {distinctValues: ['3.14']}})).toEqual({suggestion: 'decimal', values: ['3.14']})
    })
    test('violation message', () => {
        const db: Database = {entities: [{name: 'users', attrs: [{name: 'age', type: 'varchar(3)', stats: {distinctValues: ['12']}}]}]}
        expect(attributeTypeBadRule.analyze(ruleConf, now, db, [], []).map(v => v.message)).toEqual([
            'Attribute users(age) with type varchar(3) could have type int.'
        ])
    })
    test('ignores', () => {
        const db: Database = {entities: [{name: 'users', attrs: [
            {name: 'id', type: 'uuid'},
            {name: 'age', type: 'varchar(3)', stats: {distinctValues: ['12']}},
            {name: 'created_at', type: 'varchar(24)', stats: {distinctValues: ['2024-05-30T09:49:58.068Z']}},
        ]}]}
        expect(attributeTypeBadRule.analyze(ruleConf, now, db, [], []).map(v => v.message)).toEqual([
            'Attribute users(age) with type varchar(3) could have type int.',
            'Attribute users(created_at) with type varchar(24) could have type timestamp.',
        ])
        expect(attributeTypeBadRule.analyze({...ruleConf, ignores: ['users(created_at)']}, now, db, [], []).map(v => v.message)).toEqual([
            'Attribute users(age) with type varchar(3) could have type int.',
        ])
    })
})
