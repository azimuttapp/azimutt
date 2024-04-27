import {describe, expect, test} from "@jest/globals";
import {Entity} from "../../database";
import {hasEntityNoIndex} from "./entityNoIndex";

describe('entityNoIndex', () => {
    test('entity with primary key', () => {
        const users: Entity = {name: 'users', attrs: [{name: 'id', type: 'uuid'}], pk: {attrs: [['id']]}}
        expect(hasEntityNoIndex(users)).toEqual(false)
    })
    test('entity with index', () => {
        const users: Entity = {name: 'users', attrs: [{name: 'id', type: 'uuid'}], indexes: [{attrs: [['id']]}]}
        expect(hasEntityNoIndex(users)).toEqual(false)
    })
    test('invalid entity', () => {
        const users: Entity = {name: 'users', attrs: [{name: 'id', type: 'uuid'}]}
        expect(hasEntityNoIndex(users)).toEqual(true)
    })
})
