import {describe, expect, test} from "@jest/globals";
import {Entity, Relation} from "../../database";
import {getMissingIndexOnRelation} from "./indexOnRelation";

describe('indexOnRelation', () => {
    test('empty', () => {
        const postAuthor: Relation = {src: {entity: 'posts'}, ref: {entity: 'users'}, attrs: [{src: ['author'], ref: ['id']}]}
        expect(getMissingIndexOnRelation(postAuthor, {})).toEqual([])
    })
    test('has indexes', () => {
        const postAuthor: Relation = {src: {entity: 'posts'}, ref: {entity: 'users'}, attrs: [{src: ['author'], ref: ['id']}]}
        const users: Entity = {name: 'users', attrs: [], pk: {attrs: [['id']]}}
        const posts: Entity = {name: 'posts', attrs: [], indexes: [{attrs: [['author']]}]}
        expect(getMissingIndexOnRelation(postAuthor, {users, posts})).toEqual([])
    })
    test('missing indexes', () => {
        const postAuthor: Relation = {src: {entity: 'posts'}, ref: {entity: 'users'}, attrs: [{src: ['author'], ref: ['id']}]}
        const users: Entity = {name: 'users', attrs: []}
        const posts: Entity = {name: 'posts', attrs: []}
        expect(getMissingIndexOnRelation(postAuthor, {users, posts})).toEqual([
            {ref: {entity: 'users'}, attrs: [['id']]},
            {ref: {entity: 'posts'}, attrs: [['author']]},
        ])
    })
})
