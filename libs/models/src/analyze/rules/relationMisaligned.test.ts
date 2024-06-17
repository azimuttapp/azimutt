import {describe, expect, test} from "@jest/globals";
import {Database, Entity, Relation} from "../../database";
import {getMisalignedRelation, relationMisalignedRule} from "./relationMisaligned";
import {ruleConf} from "../rule.test";

describe('relationMisaligned', () => {
    const now = Date.now()
    test('valid relation', () => {
        const postAuthor: Relation = {src: {entity: 'posts'}, ref: {entity: 'users'}, attrs: [{src: ['author'], ref: ['id']}]}
        const users: Entity = {name: 'users', attrs: [{name: 'id', type: 'uuid'}]}
        const posts: Entity = {name: 'posts', attrs: [{name: 'author', type: 'uuid'}]}
        expect(getMisalignedRelation(postAuthor, {users, posts})).toEqual(undefined)
    })
    test('misaligned types', () => {
        const postAuthor: Relation = {src: {entity: 'posts'}, ref: {entity: 'users'}, attrs: [{src: ['author'], ref: ['id']}]}
        const users: Entity = {name: 'users', attrs: [{name: 'id', type: 'uuid'}]}
        const posts: Entity = {name: 'posts', attrs: [{name: 'author', type: 'string'}]}
        expect(getMisalignedRelation(postAuthor, {users, posts})).toEqual({relation: postAuthor, misalignedTypes: [
            {src: {entity: 'posts', attribute: ['author']}, srcType: 'string', ref: {entity: 'users', attribute: ['id']}, refType: 'uuid'}
        ]})
    })
    test('violation message', () => {
        const db: Database = {
            entities: [
                {name: 'users', attrs: [{name: 'id', type: 'uuid'}]},
                {name: 'posts', attrs: [{name: 'id', type: 'uuid'}, {name: 'author', type: 'varchar'}]},
            ],
            relations: [
                {src: {entity: 'posts'}, ref: {entity: 'users'}, attrs: [{src: ['author'], ref: ['id']}]},
            ]
        }
        expect(relationMisalignedRule.analyze(ruleConf, now, db, [], [], []).map(v => v.message)).toEqual([
            'Relation posts(author)->users(id) link attributes different types: posts(author): varchar != users(id): uuid',
        ])
    })
    test('ignores', () => {
        const db: Database = {
            entities: [
                {name: 'users', attrs: [{name: 'id', type: 'uuid'}]},
                {name: 'posts', attrs: [{name: 'id', type: 'uuid'}, {name: 'author', type: 'varchar'}, {name: 'created_by', type: 'text'}]},
            ],
            relations: [
                {src: {entity: 'posts'}, ref: {entity: 'users'}, attrs: [{src: ['author'], ref: ['id']}]},
                {src: {entity: 'posts'}, ref: {entity: 'users'}, attrs: [{src: ['created_by'], ref: ['id']}]},
            ]
        }
        expect(relationMisalignedRule.analyze(ruleConf, now, db, [], [], []).map(v => v.message)).toEqual([
            'Relation posts(author)->users(id) link attributes different types: posts(author): varchar != users(id): uuid',
            'Relation posts(created_by)->users(id) link attributes different types: posts(created_by): text != users(id): uuid',
        ])
        expect(relationMisalignedRule.analyze({...ruleConf, ignores: ['posts(created_by)->users(id)']}, now, db, [], [], []).map(v => v.message)).toEqual([
            'Relation posts(author)->users(id) link attributes different types: posts(author): varchar != users(id): uuid',
        ])
        expect(relationMisalignedRule.analyze(ruleConf, now, db, [], [], [{message: '', extra: {relation: {src: {entity: 'posts'}, ref: {entity: 'users'}, attrs: [{src: ['created_by'], ref: ['id']}]}}}]).map(v => v.message)).toEqual([
            'Relation posts(author)->users(id) link attributes different types: posts(author): varchar != users(id): uuid',
        ])
    })
})
