import {describe, expect, test} from "@jest/globals";
import {attributesDiff, databaseDiff} from "./databaseDiff";
import {Attribute, Database} from "./database";

describe('databaseDiff', () => {
    test('empty', () => {
        expect(databaseDiff({}, {})).toEqual({})
    })
    describe('entities', () => {
        test('create', () => {
            expect(databaseDiff({}, {entities: [{name: 'users'}]})).toEqual({entities: {created: [{i: 0, name: 'users'}]}})
        })
        test('delete', () => {
            expect(databaseDiff({entities: [{name: 'users'}]}, {})).toEqual({entities: {deleted: [{i: 0, name: 'users'}]}})
        })
        test('same', () => {
            const before = {entities: [{name: 'users'}]}
            const after = {entities: [{name: 'users'}]}
            const diff = {entities: {unchanged: [{i: 0, name: 'users'}]}}
            expect(databaseDiff(before, after)).toEqual(diff)
        })
        test('update def', () => {
            const before = {entities: [{name: 'users', def: 'SELECT * FROM users'}]}
            const after = {entities: [{name: 'users', def: 'SELECT id, name FROM users'}]}
            const diff = {entities: {updated: [{name: 'users', def: {before: 'SELECT * FROM users', after: 'SELECT id, name FROM users'}}]}}
            expect(databaseDiff(before, after)).toEqual(diff)
        })
        test('update pk', () => {
            const before = {entities: [{name: 'users', pk: {attrs: [['user_id'], ['role_id']]}}]}
            const after = {entities: [{name: 'users', pk: {attrs: [['id']]}}]}
            const diff = {entities: {updated: [{name: 'users', pk: {before: {attrs: [['user_id'], ['role_id']]}, after: {attrs: [['id']]}}}]}}
            expect(databaseDiff(before, after)).toEqual(diff)
        })
        test('update doc', () => {
            const before = {entities: [{name: 'users', doc: 'store users'}]}
            const after = {entities: [{name: 'users', doc: 'list users'}]}
            const diff = {entities: {updated: [{name: 'users', doc: {before: 'store users', after: 'list users'}}]}}
            expect(databaseDiff(before, after)).toEqual(diff)
        })
        test('update extra', () => {
            const before = {entities: [{name: 'users', extra: {}}]}
            const after = {entities: [{name: 'users', extra: {deprecated: null}}]}
            const diff = {entities: {updated: [{name: 'users', extra: {deprecated: {before: undefined, after: null}}}]}}
            expect(databaseDiff(before, after)).toEqual(diff)
        })
    })
    describe('types', () => {
        test('create', () => {
            expect(databaseDiff({}, {types: [{name: 'position'}]})).toEqual({types: {created: [{i: 0, name: 'position'}]}})
        })
        test('delete', () => {
            expect(databaseDiff({types: [{name: 'position'}]}, {})).toEqual({types: {deleted: [{i: 0, name: 'position'}]}})
        })
        test('same', () => {
            const before = {types: [{name: 'position'}]}
            const after = {types: [{name: 'position'}]}
            const diff = {types: {unchanged: [{i: 0, name: 'position'}]}}
            expect(databaseDiff(before, after)).toEqual(diff)
        })
        test('update alias', () => {
            const before = {types: [{name: 'position', alias: 'p'}]}
            const after = {types: [{name: 'position', alias: 'pos'}]}
            const diff = {types: {updated: [{name: 'position', alias: {before: 'p', after: 'pos'}}]}}
            expect(databaseDiff(before, after)).toEqual(diff)
        })
        test('update values', () => {
            const before: Database = {types: [{name: 'status', values: ['draft', 'public']}]}
            const after: Database = {types: [{name: 'status', values: ['draft', 'private']}]}
            const diff = {types: {updated: [{name: 'status', values: {before: ['draft', 'public'], after: ['draft', 'private']}}]}}
            expect(databaseDiff(before, after)).toEqual(diff)
        })
        test('update definition', () => {
            const before = {types: [{name: 'position', definition: 'range(0..10)'}]}
            const after = {types: [{name: 'position', definition: 'range(0..100)'}]}
            const diff = {types: {updated: [{name: 'position', definition: {before: 'range(0..10)', after: 'range(0..100)'}}]}}
            expect(databaseDiff(before, after)).toEqual(diff)
        })
        test('update doc', () => {
            const before = {types: [{name: 'position', doc: 'store position'}]}
            const after = {types: [{name: 'position', doc: 'save position'}]}
            const diff = {types: {updated: [{name: 'position', doc: {before: 'store position', after: 'save position'}}]}}
            expect(databaseDiff(before, after)).toEqual(diff)
        })
        test('update extra', () => {
            const before = {types: [{name: 'position', extra: {}}]}
            const after = {types: [{name: 'position', extra: {deprecated: null}}]}
            const diff = {types: {updated: [{name: 'position', extra: {deprecated: {before: undefined, after: null}}}]}}
            expect(databaseDiff(before, after)).toEqual(diff)
        })
    })
    describe('attributes', () => {
        test('create', () => {
            const before: Attribute[] = [{name: 'x', type: 'int'}, {name: 'y', type: 'int'}]
            const after: Attribute[] = [{name: 'x', type: 'int'}, {name: 'y', type: 'int'}, {name: 'z', type: 'int'}]
            const diff = {unchanged: [{i: 0, name: 'x', type: 'int'}, {i: 1, name: 'y', type: 'int'}], created: [{i: 2, name: 'z', type: 'int'}]}
            expect(attributesDiff(before, after)).toEqual(diff)
        })
        test('delete', () => {
            const before: Attribute[] = [{name: 'x', type: 'int'}, {name: 'y', type: 'int'}]
            const after: Attribute[] = [{name: 'x', type: 'int'}]
            const diff = {unchanged: [{i: 0, name: 'x', type: 'int'}], deleted: [{i: 1, name: 'y', type: 'int'}]}
            expect(attributesDiff(before, after)).toEqual(diff)
        })
        test('rename', () => {
            const before: Attribute[] = [{name: 'x', type: 'int'}, {name: 'y', type: 'int'}]
            const after: Attribute[] = [{name: 'x', type: 'int'}, {name: 'z', type: 'int'}]
            const diff = {unchanged: [{i: 0, name: 'x', type: 'int'}], created: [{i: 1, name: 'z', type: 'int'}], deleted: [{i: 1, name: 'y', type: 'int'}]}
            expect(attributesDiff(before, after)).toEqual(diff)
        })
        test('update position', () => {
            const before: Attribute[] = [{name: 'x', type: 'int'}, {name: 'y', type: 'int'}]
            const after: Attribute[] = [{name: 'y', type: 'int'}, {name: 'x', type: 'int'}]
            const diff = {updated: [{i: {before: 0, after: 1}, name: 'x'}, {i: {before: 1, after: 0}, name: 'y'}]}
            expect(attributesDiff(before, after)).toEqual(diff)
        })
        test('update type', () => {
            const before: Attribute[] = [{name: 'x', type: 'int'}, {name: 'y', type: 'int'}]
            const after: Attribute[] = [{name: 'x', type: 'int'}, {name: 'y', type: 'bigint'}]
            const diff = {unchanged: [{i: 0, name: 'x', type: 'int'}], updated: [{name: 'y', type: {before: 'int', after: 'bigint'}}]}
            expect(attributesDiff(before, after)).toEqual(diff)
        })
        test('update null', () => {
            const before: Attribute[] = [{name: 'x', type: 'int'}, {name: 'y', type: 'int', null: false}]
            const after: Attribute[] = [{name: 'x', type: 'int', null: true}, {name: 'y', type: 'int'}]
            const diff = {updated: [{name: 'x', null: {before: undefined, after: true}}, {name: 'y', null: {before: false, after: undefined}}]}
            expect(attributesDiff(before, after)).toEqual(diff)
        })
        test('update default', () => {
            const before: Attribute[] = [{name: 'x', type: 'int', default: 0}, {name: 'y', type: 'int'}]
            const after: Attribute[] = [{name: 'x', type: 'int'}, {name: 'y', type: 'int', default: '5'}]
            const diff = {updated: [{name: 'x', default: {before: 0, after: undefined}}, {name: 'y', default: {before: undefined, after: '5'}}]}
            expect(attributesDiff(before, after)).toEqual(diff)
        })
        test('update doc', () => {
            const before: Attribute[] = [{name: 'name', type: 'varchar', doc: 'user name'}]
            const after: Attribute[] = [{name: 'name', type: 'varchar', doc: 'the user name'}]
            const diff = {updated: [{name: 'name', doc: {before: 'user name', after: 'the user name'}}]}
            expect(attributesDiff(before, after)).toEqual(diff)
        })
        test('update extra', () => {
            const before: Attribute[] = [{name: 'name', type: 'varchar', extra: {}}]
            const after: Attribute[] = [{name: 'name', type: 'varchar', extra: {deprecated: null}}]
            const diff = {updated: [{name: 'name', extra: {deprecated: {before: undefined, after: null}}}]}
            expect(attributesDiff(before, after)).toEqual(diff)
        })
    })
})
