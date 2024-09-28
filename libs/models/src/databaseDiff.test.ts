import {describe, expect, test} from "@jest/globals";
import {databaseDiff, databaseEvolve} from "./databaseDiff";
import {Database} from "./database";

describe('databaseDiff', () => {
    test('same db', () => {
        expect(databaseDiff({}, {})).toEqual({})
        expect(databaseEvolve({}, {})).toEqual({})
        const db: Database = {
            entities: [
                {name: 'users', attrs: [{name: 'id', type: 'uuid'}]},
                {name: 'posts', attrs: [{name: 'id', type: 'uuid'}, {name: 'author', type: 'uuid'}]},
            ],
            relations: [{src: {entity: 'posts', attrs: [['author']]}, ref: {entity: 'users', attrs: [['id']]}}]
        }
        expect(databaseDiff(db, db)).toEqual({})
        expect(databaseEvolve(db, {})).toEqual(db)
    })
    test('drop entity', () => {
        const users = {name: 'users', attrs: [{name: 'id', type: 'uuid'}]}
        expect(databaseDiff({entities: [users]}, {})).toEqual({entities: {left: [users]}})
        expect(databaseDiff({entities: [users]}, {entities: []})).toEqual({entities: {left: [users]}})
        // expect(databaseEvolve({entities: [users]}, {entities: {left: [users]}})).toEqual({})
    })
    test('create entity', () => {
        const users = {name: 'users', attrs: [{name: 'id', type: 'uuid'}]}
        expect(databaseDiff({}, {entities: [users]})).toEqual({entities: {right: [users]}})
        expect(databaseDiff({entities: []}, {entities: [users]})).toEqual({entities: {right: [users]}})
        // expect(databaseEvolve({}, {entities: {right: [users]}})).toEqual({entities: [users]})
    })
    test('create attribute', () => {
        const leftUsers = {name: 'users', attrs: [{name: 'id', type: 'uuid'}]}
        const rightUsers = {name: 'users', attrs: [{name: 'id', type: 'uuid'}, {name: 'name', type: 'varchar'}]}
        expect(databaseDiff(
            {entities: [leftUsers]},
            {entities: [rightUsers]}
        )).toEqual({entities: {both: [{left: leftUsers, right: rightUsers, attrs: {right: [{name: "name", type: "varchar"}]}}]}})
    })
    test('drop attribute', () => {
        const leftUsers = {name: 'users', attrs: [{name: 'id', type: 'uuid'}, {name: 'name', type: 'varchar'}]}
        const rightUsers = {name: 'users', attrs: [{name: 'id', type: 'uuid'}]}
        expect(databaseDiff(
            {entities: [leftUsers]},
            {entities: [rightUsers]}
        )).toEqual({entities: {both: [{left: leftUsers, right: rightUsers, attrs: {left: [{name: "name", type: "varchar"}]}}]}})
    })
    test('update attribute', () => {
        const leftName = {name: 'name', type: 'varchar'}
        const leftUsers = {name: 'users', attrs: [{name: 'id', type: 'uuid'}, leftName]}
        const rightName = {name: 'name', type: 'text'}
        const rightUsers = {name: 'users', attrs: [{name: 'id', type: 'uuid'}, rightName]}
        expect(databaseDiff(
            {entities: [leftUsers]},
            {entities: [rightUsers]}
        )).toEqual({entities: {both: [{left: leftUsers, right: rightUsers, attrs: {both: [{left: leftName, right: rightName}]}}]}})
    })
    test('create index', () => {
        const leftUsers = {name: 'users', attrs: [{name: 'id', type: 'uuid'}]}
        const rightUsers = {name: 'users', attrs: [{name: 'id', type: 'uuid'}], indexes: [{attrs: [['id']]}]}
        expect(databaseDiff(
            {entities: [leftUsers]},
            {entities: [rightUsers]}
        )).toEqual({entities: {both: [{left: leftUsers, right: rightUsers, indexes: {right: [{attrs: [['id']]}]}}]}})
    })
    test('drop index', () => {
        const leftUsers = {name: 'users', attrs: [{name: 'id', type: 'uuid'}], indexes: [{attrs: [['id']]}]}
        const rightUsers = {name: 'users', attrs: [{name: 'id', type: 'uuid'}]}
        expect(databaseDiff(
            {entities: [leftUsers]},
            {entities: [rightUsers]}
        )).toEqual({entities: {both: [{left: leftUsers, right: rightUsers, indexes: {left: [{attrs: [['id']]}]}}]}})
    })
    test('update index', () => {
        const leftIndex = {attrs: [['id']]}
        const leftUsers = {name: 'users', attrs: [{name: 'id', type: 'uuid'}], indexes: [leftIndex]}
        const rightIndex = {attrs: [['id']], unique: true}
        const rightUsers = {name: 'users', attrs: [{name: 'id', type: 'uuid'}], indexes: [rightIndex]}
        expect(databaseDiff(
            {entities: [leftUsers]},
            {entities: [rightUsers]}
        )).toEqual({entities: {both: [{left: leftUsers, right: rightUsers, indexes: {both: [{left: leftIndex, right: rightIndex}]}}]}})
    })
})
