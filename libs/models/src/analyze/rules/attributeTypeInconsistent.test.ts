import {describe, expect, test} from "@jest/globals";
import {Database, Entity} from "../../database";
import {attributeTypeInconsistentRule, getInconsistentAttributeTypes} from "./attributeTypeInconsistent";
import {ruleConf} from "../rule.test";

describe('attributeInconsistentType', () => {
    test('empty', () => {
        expect(getInconsistentAttributeTypes([])).toEqual({})
    })
    test('all same types', () => {
        const users: Entity = {name: 'users', attrs: [{name: 'id', type: 'uuid'}, {name: 'name', type: 'varchar'}]}
        const posts: Entity = {name: 'posts', attrs: [{name: 'id', type: 'uuid'}, {name: 'name', type: 'varchar'}, {name: 'author', type: 'uuid'}]}
        const events: Entity = {name: 'events', attrs: [{name: 'details', type: 'json', attrs: [{name: 'id', type: 'uuid'}]}]}
        expect(getInconsistentAttributeTypes([users, posts, events])).toEqual({})
    })
    test('inconsistent types', () => {
        const users: Entity = {name: 'users', attrs: [{name: 'id', type: 'uuid'}, {name: 'name', type: 'varchar'}]}
        const posts: Entity = {name: 'posts', attrs: [{name: 'id', type: 'uuid'}, {name: 'name', type: 'text'}, {name: 'author', type: 'uuid'}]}
        const events: Entity = {name: 'events', attrs: [{name: 'details', type: 'json', attrs: [{name: 'id', type: 'string'}]}]}
        expect(getInconsistentAttributeTypes([users, posts, events])).toEqual({
            id: [
                {ref: {entity: 'users', attribute: ['id']}, value: {name: 'id', type: 'uuid'}},
                {ref: {entity: 'posts', attribute: ['id']}, value: {name: 'id', type: 'uuid'}},
                {ref: {entity: 'events', attribute: ['details', 'id']}, value: {name: 'id', type: 'string'}},
            ],
            name: [
                {ref: {entity: 'users', attribute: ['name']}, value: {name: 'name', type: 'varchar'}},
                {ref: {entity: 'posts', attribute: ['name']}, value: {name: 'name', type: 'text'}},
            ],
        })
    })
    test('violation message', () => {
        const db: Database = {entities: [{name: 'users', attrs: [{name: 'id', type: 'uuid'}]}, {name: 'posts', attrs: [{name: 'id', type: 'int'}]}]}
        expect(attributeTypeInconsistentRule.analyze(ruleConf, db, []).map(v => v.message)).toEqual([
            `Attribute id has several types: uuid in users(id), int in posts(id).`
        ])
    })
})
