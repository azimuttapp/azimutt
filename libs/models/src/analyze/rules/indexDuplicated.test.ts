import {describe, expect, test} from "@jest/globals";
import {Database} from "../../database";
import {getDuplicatedIndexes, indexDuplicatedRule} from "./indexDuplicated";
import {ruleConf} from "../rule.test";

describe('indexDuplicated', () => {
    test('empty', () => {
        expect(getDuplicatedIndexes({name: 'users', attrs: []})).toEqual([])
        expect(getDuplicatedIndexes({name: 'users', attrs: [], indexes: []})).toEqual([])
    })
    test('no duplicates', () => {
        expect(getDuplicatedIndexes({name: 'users', attrs: [], indexes: [
            {attrs: [['first_name', 'last_name']]},
            {attrs: [['email']], unique: true},
            {attrs: [['createdAt']]},
        ]})).toEqual([])
    })
    test('with duplicates', () => {
        const users = {name: 'users', attrs: [], indexes: [
            {attrs: [['first_name'], ['last_name']]},
            {attrs: [['first_name']]},
            {attrs: [['last_name']]},
        ]}
        expect(getDuplicatedIndexes(users)).toEqual([
            {entity: users, index: {attrs: [['first_name']]}, coveredBy: [{attrs: [['first_name'], ['last_name']]}]}
        ])
    })
    test('ignores', () => {
        const db: Database = {entities: [{name: 'users', attrs: [], indexes: [
            {attrs: [['first_name'], ['last_name']]},
            {attrs: [['first_name']]},
            {attrs: [['last_name']]},
            {attrs: [['first_name'], ['last_name'], ['email']]},
        ]}]}
        expect(indexDuplicatedRule.analyze(ruleConf, db, []).map(v => v.message)).toEqual([
            'Index on users(first_name) can be deleted, it\'s covered by: (first_name, last_name), (first_name, last_name, email).',
            'Index on users(first_name, last_name) can be deleted, it\'s covered by: (first_name, last_name, email).',
        ])
        expect(indexDuplicatedRule.analyze({...ruleConf, ignores: ['users(first_name, last_name)']}, db, []).map(v => v.message)).toEqual([
            'Index on users(first_name) can be deleted, it\'s covered by: (first_name, last_name), (first_name, last_name, email).',
        ])
    })
    test('violation message', () => {
        const db: Database = {entities: [{name: 'users', attrs: [], indexes: [
            {attrs: [['first_name'], ['last_name']]},
            {attrs: [['first_name']]},
        ]}]}
        expect(indexDuplicatedRule.analyze(ruleConf, db, []).map(v => v.message)).toEqual([
            'Index on users(first_name) can be deleted, it\'s covered by: (first_name, last_name).'
        ])
    })
})
