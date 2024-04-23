import {describe, expect, test} from "@jest/globals";
import {schemaToAttributes, sumType, ValueSchema, valuesToSchema, valueToSchema} from "../src";

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
    describe('schemaToAttributes', () => {
        test('basic', () => {
            expect(schemaToAttributes({type: 'json', values: []})).toEqual({})
            expect(schemaToAttributes({type: 'json', values: [], nested: {
                id: {type: 'int', values: []},
                name: {type: 'varchar', values: []},
            }})).toEqual({
                id: {pos: 1, name: 'id', type: 'int'},
                name: {pos: 2, name: 'name', type: 'varchar'},
            })
        })
        test('flatten levels', () => {
            const schema: ValueSchema = {type: 'json', values: [], nested: {
                id: {type: 'int', values: []},
                name: {type: 'varchar', values: []},
                details: {type: 'json', values: [], nested: {
                    github: {type: 'varchar', values: []},
                    twitter: {type: 'json', values: [], nested: {
                        id: {type: 'varchar', values: []},
                        name: {type: 'varchar', values: []},
                    }},
                }},
                settings: {type: 'json', values: []},
            }}
            expect(schemaToAttributes(schema, 0)).toEqual({
                id: {pos: 1, name: 'id', type: 'int'},
                name: {pos: 2, name: 'name', type: 'varchar'},
                details: {pos: 3, name: 'details', type: 'json', attrs: {
                    github: {pos: 1, name: 'github', type: 'varchar'},
                    twitter: {pos: 2, name: 'twitter', type: 'json', attrs: {
                        id: {pos: 1, name: 'id', type: 'varchar'},
                        name: {pos: 2, name: 'name', type: 'varchar'},
                    }},
                }},
                settings: {pos: 4, name: 'settings', type: 'json'},
            })
            expect(schemaToAttributes(schema, 1)).toEqual({
                id: {pos: 1, name: 'id', type: 'int'},
                name: {pos: 2, name: 'name', type: 'varchar'},
                details: {pos: 3, name: 'details', type: 'json'},
                'details.github': {pos: 4, name: 'details.github', type: 'varchar'},
                'details.twitter': {pos: 5, name: 'details.twitter', type: 'json', attrs: {
                    id: {pos: 1, name: 'id', type: 'varchar'},
                    name: {pos: 2, name: 'name', type: 'varchar'},
                }},
                settings: {pos: 6, name: 'settings', type: 'json'},
            })
            expect(schemaToAttributes(schema, 2)).toEqual({
                id: {pos: 1, name: 'id', type: 'int'},
                name: {pos: 2, name: 'name', type: 'varchar'},
                details: {pos: 3, name: 'details', type: 'json'},
                'details.github': {pos: 4, name: 'details.github', type: 'varchar'},
                'details.twitter': {pos: 5, name: 'details.twitter', type: 'json'},
                'details.twitter.id': {pos: 6, name: 'details.twitter.id', type: 'varchar'},
                'details.twitter.name': {pos: 7, name: 'details.twitter.name', type: 'varchar'},
                settings: {pos: 8, name: 'settings', type: 'json'},
            })
        })
    })
})
