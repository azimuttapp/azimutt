import {describe, expect, test} from "@jest/globals";
import {Database, Entity} from "../../database";
import {checkNamingConsistency, namingConsistencyRule} from "./namingConsistency";
import {ruleConf} from "../rule.test";

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
    test('ignores', () => {
        const db: Database = {
            entities: [
                {name: 'wp_users', attrs: [{name: 'user_id', type: 'uuid'}]},
                {name: 'wp_posts', attrs: [{name: 'post_id', type: 'uuid'}, {name: 'author', type: 'uuid'}]},
                {name: 'wp_tags', attrs: [{name: 'tag_id', type: 'uuid'}, {name: 'name', type: 'varchar'}]},
                {name: 'Comments', attrs: [{name: 'CommentId', type: 'uuid'}, {name: 'author', type: 'uuid'}]},
                {name: 'Forms', attrs: [{name: 'FormId', type: 'uuid'}]},
            ]
        }
        expect(namingConsistencyRule.analyze(ruleConf, db, []).map(v => v.message)).toEqual([
            'Entity Comments doesn\'t follow naming convention snake-lower.',
            'Entity Forms doesn\'t follow naming convention snake-lower.',
            'Attribute Comments(CommentId) doesn\'t follow naming convention snake-lower.',
            'Attribute Forms(FormId) doesn\'t follow naming convention snake-lower.',
        ])
        expect(namingConsistencyRule.analyze({...ruleConf, ignoreEntities: ['Forms']}, db, []).map(v => v.message)).toEqual([
            'Entity Comments doesn\'t follow naming convention snake-lower.',
            'Attribute Comments(CommentId) doesn\'t follow naming convention snake-lower.',
            'Attribute Forms(FormId) doesn\'t follow naming convention snake-lower.',
        ])
        expect(namingConsistencyRule.analyze({...ruleConf, ignoreAttributes: ['Forms(FormId)']}, db, []).map(v => v.message)).toEqual([
            'Entity Comments doesn\'t follow naming convention snake-lower.',
            'Entity Forms doesn\'t follow naming convention snake-lower.',
            'Attribute Comments(CommentId) doesn\'t follow naming convention snake-lower.',
        ])
        expect(namingConsistencyRule.analyze({...ruleConf, ignoreEntities: ['Forms'], ignoreAttributes: ['Forms(FormId)']}, db, []).map(v => v.message)).toEqual([
            'Entity Comments doesn\'t follow naming convention snake-lower.',
            'Attribute Comments(CommentId) doesn\'t follow naming convention snake-lower.',
        ])
    })
    test('violation message', () => {
        const db: Database = {
            entities: [
                {name: 'wp_users', attrs: [{name: 'user_id', type: 'uuid'}]},
                {name: 'wp_posts', attrs: [{name: 'post_id', type: 'uuid'}, {name: 'author', type: 'uuid'}]},
                {name: 'Comments', attrs: [{name: 'CommentId', type: 'uuid'}, {name: 'author', type: 'uuid'}]},
            ]
        }
        expect(namingConsistencyRule.analyze(ruleConf, db, []).map(v => v.message)).toEqual([
            'Entity Comments doesn\'t follow naming convention snake-lower.',
            'Attribute Comments(CommentId) doesn\'t follow naming convention snake-lower.'
        ])
    })
})
