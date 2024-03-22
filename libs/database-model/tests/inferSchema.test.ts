import {describe, expect, test} from "@jest/globals";
import {valueToSchema, valuesToSchema, sumType} from "../src";

describe('inferSchema', () => {
    test('infer primitive schema', () => {
        expect(valueToSchema('fr')).toEqual({type: 'string', values: ['fr']})
        expect(valueToSchema(2)).toEqual({type: 'number', values: [2]})
        expect(valueToSchema(true)).toEqual({type: 'boolean', values: [true]})
        expect(valueToSchema(null)).toEqual({type: 'null', values: [], nullable: true})
        expect(valueToSchema(undefined)).toEqual({type: 'null', values: [], nullable: true})
        const date = new Date()
        expect(valueToSchema(date)).toEqual({type: 'Date', values: [date]})
    })
    test('infer complex schema', () => {
        expect(valueToSchema([])).toEqual({type: '[]', values: [[]]})
        expect(valueToSchema(['fr', 'de'])).toEqual({type: 'string[]', values: ['fr', 'de']})
        expect(valueToSchema(['fr', 2])).toEqual({type: 'string|number[]', values: ['fr', 2]})
        expect(valueToSchema({})).toEqual({type: 'Object', values: [{}]})
        expect(valueToSchema({name: 'luc'})).toEqual({
            type: 'Object',
            values: [{name: 'luc'}],
            nested: {
                name: {type: 'string', values: ['luc']}
            }
        })
    })
    test('infer very complex schema', () => {
        const user2 = {name: 'paul', tags: ['a', 'b']}
        const user3 = {name: 'lise', tags: null, best: true}
        const user1 = {
            name: 'luc',
            friends: [user2, user3],
            tags: ['best', null, 'top']
        }
        expect(valueToSchema(user1)).toEqual({
            type: 'Object',
            values: [user1],
            nested: {
                name: {type: 'string', values: ['luc']},
                friends: {
                    type: 'Object[]',
                    values: [user2, user3],
                    nested: {
                        name: {type: 'string', values: ['paul', 'lise']},
                        tags: {type: 'string[]', values: ['a', 'b'], nullable: true},
                        best: {type: 'boolean', values: [true]}
                    }
                },
                tags: {type: 'string|null[]', values: ['best', 'top']}
            }
        })
    })
    test('infer schema for list of values', () => {
        expect(valuesToSchema(['fr', 'de'])).toEqual({type: 'string', values: ['fr', 'de']})
        expect(valuesToSchema(['fr', 2])).toEqual({type: 'string|number', values: ['fr', 2]})
        expect(valuesToSchema([{id: 1}, {name: 'luc'}, {name: null}])).toEqual({
            type: 'Object', values: [{id: 1}, {name: 'luc'}, {name: null}], nested: {
                id: {type: 'number', values: [1]},
                name: {type: 'string', values: ['luc'], nullable: true}
            }
        })
    })
    test('merge empty array type', () => {
        expect(sumType(['string', 'number'])).toEqual('string|number')
        expect(sumType(['[]', 'string[]'])).toEqual('string[]')
        expect(sumType(['[]', 'string'])).toEqual('[]|string')
    })
})
