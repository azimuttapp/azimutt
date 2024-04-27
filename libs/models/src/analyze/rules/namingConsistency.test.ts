import {describe, expect, test} from "@jest/globals";
import {checkNamingConsistency} from "./namingConsistency";
import {Entity} from "../../database";

describe('namingConsistency', () => {
    test('empty', () => {
        expect(checkNamingConsistency([])).toEqual({
            entities: {convention: 'snake-lower', invalid: []},
            attributes: {convention: 'snake-lower', invalid: []},
        })
    })
    test('valid', () => {
        const users: Entity = {name: 'User', attrs: [{name: 'id', type: 'uuid'}]}
        const posts: Entity = {name: 'Post', attrs: [{name: 'id', type: 'uuid'}, {name: 'user_id', type: 'uuid'}]}
        expect(checkNamingConsistency([users, posts])).toEqual({
            entities: {convention: 'camel-upper', invalid: []},
            attributes: {convention: 'snake-lower', invalid: []},
        })
    })
    test('invalid', () => {
        const users: Entity = {name: 'users', attrs: [{name: 'id', type: 'uuid'}, {name: 'name', type: 'uuid'}]}
        const posts: Entity = {name: 'posts', attrs: [{name: 'id', type: 'uuid'}, {name: 'status', type: 'varchar'}, {name: 'user_id', type: 'uuid'}]}
        const userPosts: Entity = {name: 'UserPost', attrs: [{name: 'UserId', type: 'uuid'}, {name: 'PostId', type: 'uuid'}]}
        expect(checkNamingConsistency([users, posts, userPosts])).toEqual({
            entities: {convention: 'camel-lower', invalid: [{entity: 'UserPost'}]},
            attributes: {convention: 'snake-lower', invalid: [{entity: 'UserPost', attribute: ['UserId']}, {entity: 'UserPost', attribute: ['PostId']}]},
        })
    })
})
