import {describe, expect, test} from "@jest/globals";
import {Database, Entity} from "../../database";
import {isPrimaryKeyTechnical, primaryKeyNotBusinessRule} from "./primaryKeyNotBusiness";
import {ruleConf} from "../rule.test";

describe('primaryKeyNotBusiness', () => {
    const now = Date.now()
    test('primary key ends with id', () => {
        const users: Entity = {name: 'users', attrs: [{name: 'id', type: 'uuid'}], pk: {attrs: [['id']]}}
        expect(isPrimaryKeyTechnical(users, [])).toEqual(true)
    })
    test('primary key has relations', () => {
        const userRoles: Entity = {name: 'user_roles', attrs: [{name: 'user', type: 'uuid'}, {name: 'role', type: 'uuid'}], pk: {attrs: [['user'], ['role']]}}
        expect(isPrimaryKeyTechnical(userRoles, [
            {src: {entity: 'user_roles', attrs: [['user']]}, ref: {entity: 'users', attrs: [['id']]}},
            {src: {entity: 'user_roles', attrs: [['role']]}, ref: {entity: 'roles', attrs: [['id']]}},
        ])).toEqual(true)
    })
    test('primary key not technical', () => {
        const users: Entity = {name: 'users', attrs: [{name: 'email', type: 'varchar'}], pk: {attrs: [['email']]}}
        expect(isPrimaryKeyTechnical(users, [])).toEqual(false)
    })
    test('no check on views or without primary key', () => {
        const users: Entity = {name: 'users', kind: 'view', attrs: [{name: 'id', type: 'uuid'}]}
        expect(isPrimaryKeyTechnical(users, [])).toEqual(true)
    })
    test('violation message', () => {
        const db: Database = {entities: [{name: 'users', attrs: [{name: 'email', type: 'varchar'}], pk: {attrs: [['email']]}}]}
        expect(primaryKeyNotBusinessRule.analyze(ruleConf, now, db, [], [], []).map(v => v.message)).toEqual([
            'Entity users should have a technical primary key, current one is: (email).'
        ])
    })
    test('ignores', () => {
        const db: Database = {entities: [
            {name: 'users', attrs: [{name: 'email', type: 'varchar'}], pk: {attrs: [['email']]}},
            {name: 'posts', attrs: [{name: 'title', type: 'varchar'}], pk: {attrs: [['title']]}},
        ]}
        expect(primaryKeyNotBusinessRule.analyze(ruleConf, now, db, [], [], []).map(v => v.message)).toEqual([
            'Entity users should have a technical primary key, current one is: (email).',
            'Entity posts should have a technical primary key, current one is: (title).',
        ])
        expect(primaryKeyNotBusinessRule.analyze({...ruleConf, ignores: ['posts']}, now, db, [], [], []).map(v => v.message)).toEqual([
            'Entity users should have a technical primary key, current one is: (email).',
        ])
        expect(primaryKeyNotBusinessRule.analyze(ruleConf, now, db, [], [], [{message: '', entity: {entity: 'posts'}}]).map(v => v.message)).toEqual([
            'Entity users should have a technical primary key, current one is: (email).',
        ])
    })
})
