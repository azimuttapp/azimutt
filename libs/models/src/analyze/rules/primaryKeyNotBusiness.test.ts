import {describe, expect, test} from "@jest/globals";
import {Database, Entity} from "../../database";
import {isPrimaryKeyTechnical, primaryKeyNotBusinessRule} from "./primaryKeyNotBusiness";
import {ruleConf} from "../rule.test";

describe('primaryKeyNotBusiness', () => {
    test('primary key ends with id', () => {
        const users: Entity = {name: 'users', attrs: [{name: 'id', type: 'uuid'}], pk: {attrs: [['id']]}}
        expect(isPrimaryKeyTechnical(users, [])).toEqual(true)
    })
    test('primary key has relations', () => {
        const userRoles: Entity = {name: 'user_roles', attrs: [{name: 'user', type: 'uuid'}, {name: 'role', type: 'uuid'}], pk: {attrs: [['user'], ['role']]}}
        expect(isPrimaryKeyTechnical(userRoles, [
            {src: {entity: 'user_roles'}, ref: {entity: 'users'}, attrs: [{src: ['user'], ref: ['id']}]},
            {src: {entity: 'user_roles'}, ref: {entity: 'roles'}, attrs: [{src: ['role'], ref: ['id']}]},
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
        expect(primaryKeyNotBusinessRule.analyze(ruleConf, db, []).map(v => v.message)).toEqual([
            'Entity users should have a technical primary key, current one is: (email).'
        ])
    })
})
