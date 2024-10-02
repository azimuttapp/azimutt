import {describe, expect, test} from "@jest/globals";
import {databaseDiff} from "./databaseDiff";
import {Database} from "./database";

describe('databaseDiff', () => {
    test('empty', () => {
        expect(databaseDiff({}, {})).toEqual({})
    })
    describe('types', () => {
        test('create type', () => {
            expect(databaseDiff({}, {types: [{name: 'position'}]})).toEqual({types: {created: [{i: 0, name: 'position'}]}})
        })
        test('delete type', () => {
            expect(databaseDiff({types: [{name: 'position'}]}, {})).toEqual({types: {deleted: [{i: 0, name: 'position'}]}})
        })
        test('same type', () => {
            const before = {types: [{name: 'position'}]}
            const after = {types: [{name: 'position'}]}
            const diff = {types: {unchanged: [{i: 0, name: 'position'}]}}
            expect(databaseDiff(before, after)).toEqual(diff)
        })
        test('type change alias', () => {
            const before = {types: [{name: 'position', alias: 'p'}]}
            const after = {types: [{name: 'position', alias: 'pos'}]}
            const diff = {types: {updated: [{name: 'position', alias: {before: 'p', after: 'pos'}}]}}
            expect(databaseDiff(before, after)).toEqual(diff)
        })
        test('type change values', () => {
            const before: Database = {types: [{name: 'status', values: ['draft', 'public']}]}
            const after: Database = {types: [{name: 'status', values: ['draft', 'private']}]}
            const diff = {types: {updated: [{name: 'status', values: {before: ['draft', 'public'], after: ['draft', 'private']}}]}}
            expect(databaseDiff(before, after)).toEqual(diff)
        })
        test('type add attribute', () => {
            const before: Database = {types: [{name: 'position', attrs: [{name: 'x', type: 'int'}, {name: 'y', type: 'int'}]}]}
            const after: Database = {types: [{name: 'position', attrs: [{name: 'x', type: 'int'}, {name: 'y', type: 'int'}, {name: 'z', type: 'int'}]}]}
            const diff = {types: {updated: [{name: 'position', attrs: {unchanged: [{i: 0, name: 'x', type: 'int'}, {i: 1, name: 'y', type: 'int'}], created: [{i: 2, name: 'z', type: 'int'}]}}]}}
            expect(databaseDiff(before, after)).toEqual(diff)
        })
        test('type drop attribute', () => {
            const before: Database = {types: [{name: 'position', attrs: [{name: 'x', type: 'int'}, {name: 'y', type: 'int'}]}]}
            const after: Database = {types: [{name: 'position', attrs: [{name: 'x', type: 'int'}]}]}
            const diff = {types: {updated: [{name: 'position', attrs: {unchanged: [{i: 0, name: 'x', type: 'int'}], deleted: [{i: 1, name: 'y', type: 'int'}]}}]}}
            expect(databaseDiff(before, after)).toEqual(diff)
        })
        test('type change attribute type', () => {
            const before: Database = {types: [{name: 'position', attrs: [{name: 'x', type: 'int'}, {name: 'y', type: 'int'}]}]}
            const after: Database = {types: [{name: 'position', attrs: [{name: 'x', type: 'int'}, {name: 'y', type: 'bigint'}]}]}
            const diff = {types: {updated: [{name: 'position', attrs: {unchanged: [{i: 0, name: 'x', type: 'int'}], updated: [{name: 'y', type: {before: 'int', after: 'bigint'}}]}}]}}
            expect(databaseDiff(before, after)).toEqual(diff)
        })
        test('type rename attribute', () => {
            const before: Database = {types: [{name: 'position', attrs: [{name: 'x', type: 'int'}, {name: 'y', type: 'int'}]}]}
            const after: Database = {types: [{name: 'position', attrs: [{name: 'x', type: 'int'}, {name: 'z', type: 'int'}]}]}
            const diff = {types: {updated: [{name: 'position', attrs: {unchanged: [{i: 0, name: 'x', type: 'int'}], created: [{i: 1, name: 'z', type: 'int'}], deleted: [{i: 1, name: 'y', type: 'int'}]}}]}}
            expect(databaseDiff(before, after)).toEqual(diff)
        })
        test('type change attribute position', () => {
            const before: Database = {types: [{name: 'position', attrs: [{name: 'x', type: 'int'}, {name: 'y', type: 'int'}]}]}
            const after: Database = {types: [{name: 'position', attrs: [{name: 'y', type: 'int'}, {name: 'x', type: 'int'}]}]}
            const diff = {types: {updated: [{name: 'position', attrs: {updated: [{i: {before: 0, after: 1}, name: 'x'}, {i: {before: 1, after: 0}, name: 'y'}]}}]}}
            expect(databaseDiff(before, after)).toEqual(diff)
        })
        test('type change definition', () => {
            const before = {types: [{name: 'position', definition: 'range(0..10)'}]}
            const after = {types: [{name: 'position', definition: 'range(0..100)'}]}
            const diff = {types: {updated: [{name: 'position', definition: {before: 'range(0..10)', after: 'range(0..100)'}}]}}
            expect(databaseDiff(before, after)).toEqual(diff)
        })
        test('type change doc', () => {
            const before = {types: [{name: 'position', doc: 'store position'}]}
            const after = {types: [{name: 'position', doc: 'save position'}]}
            const diff = {types: {updated: [{name: 'position', doc: {before: 'store position', after: 'save position'}}]}}
            expect(databaseDiff(before, after)).toEqual(diff)
        })
        test('type change extra', () => {
            const before = {types: [{name: 'position', extra: {}}]}
            const after = {types: [{name: 'position', extra: {deprecated: null}}]}
            const diff = {types: {updated: [{name: 'position', extra: {deprecated: {before: undefined, after: null}}}]}}
            expect(databaseDiff(before, after)).toEqual(diff)
        })
    })
})
