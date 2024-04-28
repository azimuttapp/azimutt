import {describe, expect, test} from "@jest/globals";
import {Database, Entity, Relation} from "../../database";
import {getMissingIndexOnRelation, indexOnRelationRule} from "./indexOnRelation";

describe('indexOnRelation', () => {
    test('empty', () => {
        const postAuthor: Relation = {src: {entity: 'posts'}, ref: {entity: 'users'}, attrs: [{src: ['author'], ref: ['id']}]}
        expect(getMissingIndexOnRelation(postAuthor, {})).toEqual([])
    })
    test('has indexes', () => {
        const postAuthor: Relation = {src: {entity: 'posts'}, ref: {entity: 'users'}, attrs: [{src: ['author'], ref: ['id']}]}
        const users: Entity = {name: 'users', attrs: [{name: 'id', type: 'uuid'}], pk: {attrs: [['id']]}}
        const posts: Entity = {name: 'posts', attrs: [{name: 'id', type: 'uuid'}, {name: 'author', type: 'uuid'}], indexes: [{attrs: [['author']]}]}
        expect(getMissingIndexOnRelation(postAuthor, {users, posts})).toEqual([])
    })
    test('missing indexes', () => {
        const postAuthor: Relation = {src: {entity: 'posts'}, ref: {entity: 'users'}, attrs: [{src: ['author'], ref: ['id']}]}
        const users: Entity = {name: 'users', attrs: [{name: 'id', type: 'uuid'}]}
        const posts: Entity = {name: 'posts', attrs: [{name: 'id', type: 'uuid'}, {name: 'author', type: 'uuid'}]}
        expect(getMissingIndexOnRelation(postAuthor, {users, posts})).toEqual([
            {relation: postAuthor, ref: {entity: 'users'}, attrs: [['id']]},
            {relation: postAuthor, ref: {entity: 'posts'}, attrs: [['author']]},
        ])
    })
    test('violation message', () => {
        const db: Database = {
            entities: [
                {name: 'users', attrs: [{name: 'id', type: 'uuid'}], pk: {attrs: [['id']]}},
                {name: 'posts', attrs: [{name: 'id', type: 'uuid'}, {name: 'author', type: 'uuid'}]},
            ],
            relations: [
                {src: {entity: 'posts'}, ref: {entity: 'users'}, attrs: [{src: ['author'], ref: ['id']}]}
            ]
        }
        expect(indexOnRelationRule.analyze(db).map(v => v.message)).toEqual([
            'Create an index on posts(author) to improve posts(author)->users(id) relation.'
        ])
    })
})
