import {describe, expect, test} from "@jest/globals";
import {Entity} from "../../database";
import {isEntityTooLarge} from "./entityTooLarge";

describe('entityTooLarge', () => {
    test('valid entity', () => {
        const users: Entity = {name: 'users', attrs: [{name: 'id', type: 'uuid'}], pk: {attrs: [['id']]}}
        expect(isEntityTooLarge(users)).toEqual(false)
    })
    test('invalid entity', () => {
        const attrs1 = ['id', 'first_name', 'last_name', 'role', 'address', 'twitter', 'github', 'facebook', 'instagram', 'linkedin']
        const attrs2 = ['q1', 'q2', 'q3', 'q4', 'q5', 'q6', 'q7', 'q8', 'q9', 'q10']
        const attrs3 = ['a1', 'a2', 'a3', 'a4', 'a5', 'a6', 'a7', 'a8', 'a9', 'a10']
        const attrs4 = ['created_at', 'created_by', 'updated_at', 'updated_by', 'deleted_at', 'deleted_by']
        const attrs = attrs1.concat(attrs2, attrs3, attrs4)
        const users: Entity = {name: 'users', attrs: attrs.map(name => ({name, type: 'varchar'}))}
        expect(isEntityTooLarge(users)).toEqual(true)
    })
})
