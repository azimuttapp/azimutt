import {describe, expect, test} from "@jest/globals";
import {Entity, Relation} from "../../database";
import {getMisalignedRelation} from "./relationMisaligned";

describe('relationMisaligned', () => {
    test('valid relation', () => {
        const postAuthor: Relation = {src: {entity: 'posts'}, ref: {entity: 'users'}, attrs: [{src: ['author'], ref: ['id']}]}
        const users: Entity = {name: 'users', attrs: [{name: 'id', type: 'uuid'}]}
        const posts: Entity = {name: 'posts', attrs: [{name: 'author', type: 'uuid'}]}
        expect(getMisalignedRelation(postAuthor, {users, posts})).toEqual(undefined)
    })
    test('missing entity', () => {
        const postAuthor: Relation = {src: {entity: 'posts'}, ref: {entity: 'users'}, attrs: [{src: ['author'], ref: ['id']}]}
        const users: Entity = {name: 'users', attrs: [{name: 'id', type: 'uuid'}]}
        expect(getMisalignedRelation(postAuthor, {users})).toEqual({relation: postAuthor, missingEntities: [
            {entity: 'posts'}
        ]})
        expect(getMisalignedRelation(postAuthor, {})).toEqual({relation: postAuthor, missingEntities: [
            {entity: 'posts'},
            {entity: 'users'}
        ]})
    })
    test('missing attributes', () => {
        const postAuthor: Relation = {src: {entity: 'posts'}, ref: {entity: 'users'}, attrs: [{src: ['author'], ref: ['id']}]}
        const users: Entity = {name: 'users', attrs: [{name: 'id', type: 'uuid'}]}
        const posts: Entity = {name: 'posts', attrs: [{name: 'author', type: 'uuid'}]}
        expect(getMisalignedRelation(postAuthor, {users, posts: {name: 'posts', attrs: []}})).toEqual({relation: postAuthor, missingAttrs: [
            {entity: 'posts', attribute: ['author']}
        ]})
        expect(getMisalignedRelation(postAuthor, {users: {name: 'users', attrs: []}, posts: {name: 'posts', attrs: []}})).toEqual({relation: postAuthor, missingAttrs: [
            {entity: 'posts', attribute: ['author']},
            {entity: 'users', attribute: ['id']}
        ]})
    })
    test('misaligned types', () => {
        const postAuthor: Relation = {src: {entity: 'posts'}, ref: {entity: 'users'}, attrs: [{src: ['author'], ref: ['id']}]}
        const users: Entity = {name: 'users', attrs: [{name: 'id', type: 'uuid'}]}
        const posts: Entity = {name: 'posts', attrs: [{name: 'author', type: 'string'}]}
        expect(getMisalignedRelation(postAuthor, {users, posts})).toEqual({relation: postAuthor, misalignedTypes: [
            {src: {entity: 'posts', attribute: ['author']}, srcType: 'string', ref: {entity: 'users', attribute: ['id']}, refType: 'uuid'}
        ]})
    })
})
