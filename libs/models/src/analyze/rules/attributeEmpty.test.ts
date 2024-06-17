import {describe, expect, test} from "@jest/globals";
import {Attribute, Database} from "../../database";
import {attributeEmptyRule, isAttributeEmpty} from "./attributeEmpty";
import {ruleConf} from "../rule.test";

describe('attributeEmpty', () => {
    const now = Date.now()
    test('valid entity', () => {
        const id: Attribute = {name: 'id', type: 'uuid'}
        const bio: Attribute = {name: 'bio', type: 'text', null: true}
        const name: Attribute = {name: 'name', type: 'text', null: true, stats: {cardinality: 5, nulls: 3}}
        expect(isAttributeEmpty(id)).toEqual(false)
        expect(isAttributeEmpty(bio)).toEqual(false)
        expect(isAttributeEmpty(name)).toEqual(false)
    })
    test('invalid entity', () => {
        const deletedAt: Attribute = {name: 'deleted_at', type: 'timestamp', null: true, stats: {cardinality: 0}}
        const archivedAt: Attribute = {name: 'archived_at', type: 'timestamp', null: true, stats: {nulls: 1}}
        expect(isAttributeEmpty(deletedAt)).toEqual(true)
        expect(isAttributeEmpty(archivedAt)).toEqual(true)
    })
    test('violation message', () => {
        const db: Database = {entities: [{name: 'users', attrs: [{name: 'deleted_at', type: 'timestamp', null: true, stats: {cardinality: 0}}]}]}
        expect(attributeEmptyRule.analyze(ruleConf, now, db, [], [], []).map(v => v.message)).toEqual([
            'Attribute users(deleted_at) is empty.'
        ])
    })
    test('ignores', () => {
        const db: Database = {entities: [{name: 'users', attrs: [
            {name: 'id', type: 'uuid'},
            {name: 'archived_at', type: 'timestamp', null: true, stats: {nulls: 1}},
            {name: 'deleted_at', type: 'timestamp', null: true, stats: {cardinality: 0}},
        ]}]}
        expect(attributeEmptyRule.analyze(ruleConf, now, db, [], [], []).map(v => v.message)).toEqual([
            'Attribute users(archived_at) is empty.',
            'Attribute users(deleted_at) is empty.',
        ])
        expect(attributeEmptyRule.analyze({...ruleConf, ignores: ['users(deleted_at)']}, now, db, [], [], []).map(v => v.message)).toEqual([
            'Attribute users(archived_at) is empty.',
        ])
        expect(attributeEmptyRule.analyze(ruleConf, now, db, [], [], [{message: '', entity: {entity: 'users'}, attribute: ['deleted_at']}]).map(v => v.message)).toEqual([
            'Attribute users(archived_at) is empty.',
        ])
    })
})
