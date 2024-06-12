import {describe, expect, test} from "@jest/globals";
import {Database, Entity, Relation} from "../../database";
import {getMissingAttributeRelations, relationMissAttributeRule} from "./relationMissAttribute";
import {ruleConf} from "../rule.test";

describe('relationMissAttribute', () => {
    const now = Date.now()
    test('valid relation', () => {
        const postAuthor: Relation = {src: {entity: 'posts'}, ref: {entity: 'users'}, attrs: [{src: ['author'], ref: ['id']}]}
        const users: Entity = {name: 'users', attrs: [{name: 'id', type: 'uuid'}]}
        const posts: Entity = {name: 'posts', attrs: [{name: 'author', type: 'uuid'}]}
        expect(getMissingAttributeRelations(postAuthor, {users, posts})).toEqual(undefined)
    })
    test('missing attributes', () => {
        const postAuthor: Relation = {src: {entity: 'posts'}, ref: {entity: 'users'}, attrs: [{src: ['author'], ref: ['id']}]}
        const users: Entity = {name: 'users', attrs: [{name: 'id', type: 'uuid'}]}
        expect(getMissingAttributeRelations(postAuthor, {users, posts: {name: 'posts', attrs: []}})).toEqual({relation: postAuthor, missing: [
            {entity: 'posts', attribute: ['author']}
        ]})
        expect(getMissingAttributeRelations(postAuthor, {users: {name: 'users', attrs: []}, posts: {name: 'posts', attrs: []}})).toEqual({relation: postAuthor, missing: [
            {entity: 'posts', attribute: ['author']},
            {entity: 'users', attribute: ['id']}
        ]})
    })
    test('violation message', () => {
        const db: Database = {
            entities: [
                {name: 'users', attrs: [{name: 'id', type: 'uuid'}]},
                {name: 'posts', attrs: [{name: 'id', type: 'uuid'}]},
            ],
            relations: [
                {src: {entity: 'posts'}, ref: {entity: 'users'}, attrs: [{src: ['created_by'], ref: ['id']}]},
            ]
        }
        expect(relationMissAttributeRule.analyze(ruleConf, now, db, [], [], []).map(v => v.message)).toEqual([
            'Relation posts(created_by)->users(id), not found attributes: posts(created_by)',
        ])
    })
    test('ignores', () => {
        const db: Database = {
            entities: [
                {name: 'users', attrs: [{name: 'id', type: 'uuid'}]},
                {name: 'posts', attrs: [{name: 'id', type: 'uuid'}]},
                {name: 'events', attrs: [{name: 'id', type: 'uuid'}]},
            ],
            relations: [
                {src: {entity: 'posts'}, ref: {entity: 'users'}, attrs: [{src: ['created_by'], ref: ['id']}]},
                {src: {entity: 'events'}, ref: {entity: 'users'}, attrs: [{src: ['created_by'], ref: ['email']}]},
            ]
        }
        expect(relationMissAttributeRule.analyze(ruleConf, now, db, [], [], []).map(v => v.message)).toEqual([
            'Relation posts(created_by)->users(id), not found attributes: posts(created_by)',
            'Relation events(created_by)->users(email), not found attributes: events(created_by), users(email)',
        ])
        expect(relationMissAttributeRule.analyze({...ruleConf, ignores: ['events(created_by)']}, now, db, [], [], []).map(v => v.message)).toEqual([
            'Relation posts(created_by)->users(id), not found attributes: posts(created_by)',
            'Relation events(created_by)->users(email), not found attributes: users(email)',
        ])
        expect(relationMissAttributeRule.analyze({...ruleConf, ignores: ['events(created_by)', 'users(email)']}, now, db, [], [], []).map(v => v.message)).toEqual([
            'Relation posts(created_by)->users(id), not found attributes: posts(created_by)',
        ])
        expect(relationMissAttributeRule.analyze(ruleConf, now, db, [], [], [{message: '', extra: {relation: {src: {entity: 'events'}, ref: {entity: 'users'}, attrs: [{src: ['created_by'], ref: ['email']}]}}}]).map(v => v.message)).toEqual([
            'Relation posts(created_by)->users(id), not found attributes: posts(created_by)',
        ])
    })
})
