import {describe, expect, test} from "@jest/globals";
import {Database, Entity, Relation} from "../../database";
import {getMissingEntityRelations, relationMissEntityRule} from "./relationMissEntity";
import {ruleConf} from "../rule.test";

describe('relationMissEntity', () => {
    const now = Date.now()
    test('valid relation', () => {
        const postAuthor: Relation = {src: {entity: 'posts'}, ref: {entity: 'users'}, attrs: [{src: ['author'], ref: ['id']}]}
        const users: Entity = {name: 'users', attrs: [{name: 'id', type: 'uuid'}]}
        const posts: Entity = {name: 'posts', attrs: [{name: 'author', type: 'uuid'}]}
        expect(getMissingEntityRelations(postAuthor, {users, posts})).toEqual(undefined)
    })
    test('missing entity', () => {
        const postAuthor: Relation = {src: {entity: 'posts'}, ref: {entity: 'users'}, attrs: [{src: ['author'], ref: ['id']}]}
        const users: Entity = {name: 'users', attrs: [{name: 'id', type: 'uuid'}]}
        expect(getMissingEntityRelations(postAuthor, {users})).toEqual({relation: postAuthor, missing: [
            {entity: 'posts'}
        ]})
        expect(getMissingEntityRelations(postAuthor, {})).toEqual({relation: postAuthor, missing: [
            {entity: 'posts'},
            {entity: 'users'}
        ]})
    })
    test('violation message', () => {
        const db: Database = {entities: [], relations: [{src: {entity: 'posts'}, ref: {entity: 'users'}, attrs: [{src: ['author'], ref: ['id']}]},]}
        expect(relationMissEntityRule.analyze(ruleConf, now, db, [], [], []).map(v => v.message)).toEqual([
            'Relation posts(author)->users(id), not found entities: posts, users',
        ])
    })
    test('ignores', () => {
        const db: Database = {entities: [], relations: [
            {src: {entity: 'posts'}, ref: {entity: 'users'}, attrs: [{src: ['author'], ref: ['id']}]},
            {src: {entity: 'events'}, ref: {entity: 'users'}, attrs: [{src: ['created_by'], ref: ['id']}]},
        ]}
        expect(relationMissEntityRule.analyze(ruleConf, now, db, [], [], []).map(v => v.message)).toEqual([
            'Relation posts(author)->users(id), not found entities: posts, users',
            'Relation events(created_by)->users(id), not found entities: events, users',
        ])
        expect(relationMissEntityRule.analyze({...ruleConf, ignores: ['events', 'users']}, now, db, [], [], []).map(v => v.message)).toEqual([
            'Relation posts(author)->users(id), not found entities: posts',
        ])
        expect(relationMissEntityRule.analyze(ruleConf, now, db, [], [], [{message: '', extra: {relation: {src: {entity: 'events'}, ref: {entity: 'users'}, attrs: [{src: ['created_by'], ref: ['id']}]}}}]).map(v => v.message)).toEqual([
            'Relation posts(author)->users(id), not found entities: posts, users',
        ])
    })
})
