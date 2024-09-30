import {describe, expect, test} from "@jest/globals";
import {Database} from "../../database";
import {getMissingRelations, relationMissingRule} from "./relationMissing";
import {ruleConf} from "../rule.test";

describe('relationMissing', () => {
    const now = Date.now()
    test('empty', () => {
        expect(getMissingRelations([], [])).toEqual([])
    })
    test('basic relation', () => {
        expect(getMissingRelations([
            {name: 'user', attrs: [{name: 'id', type: 'uuid'}]},
            {name: 'post', attrs: [{name: 'id', type: 'uuid'}, {name: 'user_id', type: 'uuid'}]},
        ], [])).toEqual([{src: {entity: 'post', attrs: [['user_id']]}, ref: {entity: 'user', attrs: [['id']]}, origin: 'infer-name'}])
    })
    test('entity with plural name', () => {
        expect(getMissingRelations([
            {name: 'users', attrs: [{name: 'id', type: 'uuid'}]},
            {name: 'posts', attrs: [{name: 'id', type: 'uuid'}, {name: 'user_id', type: 'uuid'}]},
        ], [])).toEqual([{src: {entity: 'posts', attrs: [['user_id']]}, ref: {entity: 'users', attrs: [['id']]}, origin: 'infer-name'}])
    })
    test('attribute lists', () => {
        expect(getMissingRelations([
            {name: 'users', attrs: [{name: 'id', type: 'uuid'}]},
            {name: 'posts', attrs: [{name: 'id', type: 'uuid'}, {name: 'user_ids', type: 'uuid[]'}]},
        ], [])).toEqual([{src: {entity: 'posts', attrs: [['user_ids']]}, ref: {entity: 'users', attrs: [['id']]}, origin: 'infer-name'}])
    })
    test('attribute without separator', () => {
        expect(getMissingRelations([
            {name: 'users', attrs: [{name: 'id', type: 'uuid'}]},
            {name: 'posts', attrs: [{name: 'id', type: 'uuid'}, {name: 'userid', type: 'uuid'}]},
        ], [])).toEqual([{src: {entity: 'posts', attrs: [['userid']]}, ref: {entity: 'users', attrs: [['id']]}, origin: 'infer-name'}])
    })
    test('entity name with prefix', () => {
        expect(getMissingRelations([
            {name: 'wp_users', attrs: [{name: 'id', type: 'uuid'}]},
            {name: 'wp_posts', attrs: [{name: 'id', type: 'uuid'}, {name: 'user_id', type: 'uuid'}]},
        ], [])).toEqual([{src: {entity: 'wp_posts', attrs: [['user_id']]}, ref: {entity: 'wp_users', attrs: [['id']]}, origin: 'infer-name'}])
    })
    test('attribute name with prefix', () => {
        expect(getMissingRelations([
            {name: 'users', attrs: [{name: 'id', type: 'uuid'}]},
            {name: 'posts', attrs: [{name: 'id', type: 'uuid'}, {name: 'author_user_id', type: 'uuid'}]},
        ], [])).toEqual([{src: {entity: 'posts', attrs: [['author_user_id']]}, ref: {entity: 'users', attrs: [['id']]}, origin: 'infer-name'}])
    })
    test('attribute id prefixed with entity name', () => {
        expect(getMissingRelations([
            {name: 'users', attrs: [{name: 'userid', type: 'uuid'}]},
            {name: 'posts', attrs: [{name: 'postid', type: 'uuid'}, {name: 'userid', type: 'uuid'}]},
        ], [])).toEqual([{src: {entity: 'posts', attrs: [['userid']]}, ref: {entity: 'users', attrs: [['userid']]}, origin: 'infer-name'}])
        expect(getMissingRelations([
            {name: 'users', attrs: [{name: 'user_id', type: 'uuid'}]},
            {name: 'posts', attrs: [{name: 'post_id', type: 'uuid'}, {name: 'user_id', type: 'uuid'}]},
        ], [])).toEqual([{src: {entity: 'posts', attrs: [['user_id']]}, ref: {entity: 'users', attrs: [['user_id']]}, origin: 'infer-name'}])
    })
    test('multi-word entity', () => {
        expect(getMissingRelations([
            {name: 'user_profiles', attrs: [{name: 'id', type: 'uuid'}]},
            {name: 'settings', attrs: [{name: 'id', type: 'uuid'}, {name: 'user_profile_id', type: 'uuid'}]},
        ], [])).toEqual([{src: {entity: 'settings', attrs: [['user_profile_id']]}, ref: {entity: 'user_profiles', attrs: [['id']]}, origin: 'infer-name'}])
    })
    test('polymorphic relation', () => {
        expect(getMissingRelations([
            {name: 'posts', attrs: [{name: 'id', type: 'uuid'}]},
            {name: 'comments', attrs: [{name: 'id', type: 'uuid'}]},
            {name: 'events', attrs: [{name: 'id', type: 'uuid'}, {name: 'item_kind', type: 'uuid', stats: {distinctValues: ['Post', 'Comment']}}, {name: 'item_id', type: 'uuid'}]},
        ], [])).toEqual([
            {src: {entity: 'events', attrs: [['item_id']]}, ref: {entity: 'posts', attrs: [['id']]}, polymorphic: {attribute: ['item_kind'], value: 'Post'}, origin: 'infer-name'},
            {src: {entity: 'events', attrs: [['item_id']]}, ref: {entity: 'comments', attrs: [['id']]}, polymorphic: {attribute: ['item_kind'], value: 'Comment'}, origin: 'infer-name'},
        ])
    })
    test.skip('composite relation', () => {
        expect(getMissingRelations([
            {name: 'users', attrs: [{name: 'id', type: 'uuid'}]},
            {name: 'organizations', attrs: [{name: 'id', type: 'uuid'}]},
            {name: 'organization_members', attrs: [{name: 'user_id', type: 'uuid'}, {name: 'organization_id', type: 'uuid'}], pk: {attrs: [['user_id'], ['organization_id']]}},
            {name: 'organization_member_roles', attrs: [{name: 'user_id', type: 'uuid'}, {name: 'organization_id', type: 'uuid'}]},
        ], [
            {src: {entity: 'organization_members', attrs: [['user_id']]}, ref: {entity: 'users', attrs: [['id']]}},
            {src: {entity: 'organization_members', attrs: [['organization_id']]}, ref: {entity: 'organizations', attrs: [['id']]}},
        ])).toEqual([
            {src: {entity: 'organization_member_roles'}, ref: {entity: 'organization_members'}, attrs: [{src: ['user_id'], ref: ['user_id']}, {src: ['organization_id'], ref: ['organization_id']}], origin: 'infer-name'}
        ])
    })
    test('users and accounts', () => {
        expect(getMissingRelations([
            {name: 'users', attrs: [{name: 'id', type: 'uuid'}]},
            {name: 'posts', attrs: [{name: 'id', type: 'uuid'}, {name: 'created_by', type: 'uuid'}]},
        ], [])).toEqual([{src: {entity: 'posts', attrs: [['created_by']]}, ref: {entity: 'users', attrs: [['id']]}, origin: 'infer-name'}])
        expect(getMissingRelations([
            {name: 'account', attrs: [{name: 'id', type: 'uuid'}]},
            {name: 'posts', attrs: [{name: 'id', type: 'uuid'}, {name: 'created_by', type: 'uuid'}]},
        ], [])).toEqual([{src: {entity: 'posts', attrs: [['created_by']]}, ref: {entity: 'account', attrs: [['id']]}, origin: 'infer-name'}])
    })
    // TODO: suggest relations even when target entity is not found
    test('violation message', () => {
        const db: Database = {
            entities: [
                {name: 'users', attrs: [{name: 'id', type: 'uuid'}]},
                {name: 'posts', attrs: [{name: 'id', type: 'uuid'}, {name: 'user_id', type: 'uuid'}]},
            ]
        }
        expect(relationMissingRule.analyze(ruleConf, now, db, [], [], []).map(v => v.message)).toEqual([
            'Create a relation from posts(user_id) to users(id).'
        ])
    })
    test('ignores', () => {
        const db: Database = {
            entities: [
                {name: 'users', attrs: [{name: 'id', type: 'uuid'}]},
                {name: 'posts', attrs: [{name: 'id', type: 'uuid'}, {name: 'user_id', type: 'uuid'}]},
                {name: 'events', attrs: [{name: 'id', type: 'uuid'}, {name: 'name', type: 'varchar'}, {name: 'created_by', type: 'uuid'}]},
            ]
        }
        expect(relationMissingRule.analyze(ruleConf, now, db, [], [], []).map(v => v.message)).toEqual([
            'Create a relation from posts(user_id) to users(id).',
            'Create a relation from events(created_by) to users(id).',
        ])
        expect(relationMissingRule.analyze({...ruleConf, ignores: ['events(created_by)->users(id)']}, now, db, [], [], []).map(v => v.message)).toEqual([
            'Create a relation from posts(user_id) to users(id).',
        ])
        expect(relationMissingRule.analyze(ruleConf, now, db, [], [], [{message: '', extra: {relation: {src: {entity: 'events', attrs: [['created_by']]}, ref: {entity: 'users', attrs: [['id']]}}}}]).map(v => v.message)).toEqual([
            'Create a relation from posts(user_id) to users(id).',
        ])
    })
})
