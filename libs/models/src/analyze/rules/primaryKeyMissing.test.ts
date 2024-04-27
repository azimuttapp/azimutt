import {describe, expect, test} from "@jest/globals";
import {Entity} from "../../database";
import {isPrimaryKeysMissing} from "./primaryKeyMissing";

describe('primaryKeyMissing', () => {
    test('valid entity', () => {
        const users: Entity = {name: 'users', attrs: [{name: 'id', type: 'uuid'}], pk: {attrs: [['id']]}}
        expect(isPrimaryKeysMissing(users)).toEqual(false)
    })
    test('missing primary key', () => {
        const users: Entity = {name: 'users', attrs: [{name: 'id', type: 'uuid'}]}
        expect(isPrimaryKeysMissing(users)).toEqual(true)
    })
    test('no missing primary key on views', () => {
        const users: Entity = {name: 'users', kind: 'view', attrs: [{name: 'id', type: 'uuid'}]}
        expect(isPrimaryKeysMissing(users)).toEqual(false)
    })
})
