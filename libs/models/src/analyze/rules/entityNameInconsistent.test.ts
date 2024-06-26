import {describe, expect, test} from "@jest/globals";
import {Database, Entity} from "../../database";
import {checkNamingConsistency, entityNameInconsistentRule} from "./entityNameInconsistent";
import {ruleConf} from "../rule.test";

describe('entityNameInconsistent', () => {
    const now = Date.now()
    test('empty', () => {
        expect(checkNamingConsistency([])).toEqual({convention: 'snake-lower', invalid: []})
    })
    test('valid', () => {
        const users: Entity = {name: 'User', attrs: [{name: 'id', type: 'uuid'}]}
        const posts: Entity = {name: 'Post', attrs: [{name: 'id', type: 'uuid'}, {name: 'user_id', type: 'uuid'}]}
        expect(checkNamingConsistency([users, posts])).toEqual({convention: 'camel-upper', invalid: []})
    })
    test('invalid', () => {
        const users: Entity = {name: 'users', attrs: [{name: 'id', type: 'uuid'}, {name: 'name', type: 'uuid'}]}
        const posts: Entity = {name: 'posts', attrs: [{name: 'id', type: 'uuid'}, {name: 'status', type: 'varchar'}, {name: 'user_id', type: 'uuid'}]}
        const userPosts: Entity = {name: 'UserPost', attrs: [{name: 'UserId', type: 'uuid'}, {name: 'PostId', type: 'uuid'}]}
        expect(checkNamingConsistency([users, posts, userPosts])).toEqual({convention: 'camel-lower', invalid: [{entity: 'UserPost'}]})
    })
    test('violation message', () => {
        const db: Database = {
            entities: [
                {name: 'wp_users', attrs: [{name: 'user_id', type: 'uuid'}]},
                {name: 'wp_posts', attrs: [{name: 'post_id', type: 'uuid'}, {name: 'author', type: 'uuid'}]},
                {name: 'Comments', attrs: [{name: 'CommentId', type: 'uuid'}, {name: 'author', type: 'uuid'}]},
            ]
        }
        expect(entityNameInconsistentRule.analyze(ruleConf, now, db, [], [], []).map(v => v.message)).toEqual([
            'Entity Comments doesn\'t follow naming convention snake-lower.',
        ])
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
        expect(entityNameInconsistentRule.analyze(ruleConf, now, db, [], [], []).map(v => v.message)).toEqual([
            'Entity Comments doesn\'t follow naming convention snake-lower.',
            'Entity Forms doesn\'t follow naming convention snake-lower.',
        ])
        expect(entityNameInconsistentRule.analyze({...ruleConf, ignores: ['Forms']}, now, db, [], [], []).map(v => v.message)).toEqual([
            'Entity Comments doesn\'t follow naming convention snake-lower.',
        ])
        expect(entityNameInconsistentRule.analyze(ruleConf, now, db, [], [], [{message: '', entity: {entity: 'Forms'}}]).map(v => v.message)).toEqual([
            'Entity Comments doesn\'t follow naming convention snake-lower.',
        ])
    })
})
