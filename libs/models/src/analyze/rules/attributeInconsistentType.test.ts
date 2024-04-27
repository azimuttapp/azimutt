import {describe, expect, test} from "@jest/globals";
import {getInconsistentAttributeTypes} from "./attributeInconsistentType";
import {Entity} from "../../database";

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
})
