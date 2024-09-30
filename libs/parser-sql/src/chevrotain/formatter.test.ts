import {describe, expect, test} from "@jest/globals";
import {tokenPosition} from "@azimutt/models";
import {format} from "./formatter";

describe('chevrotain formatter', () => {
    test('empty', () => {
        expect(format([])).toEqual([])
    })
    describe('select', () => {
        test('basic', () => {
            expect(format([{
                command: 'SELECT',
                result: {columns: [
                    {column: {wildcard: '*', parser: tokenPosition(7, 7, 1, 8, 1, 8)}}
                ]},
                from: {table: {identifier: 'users', parser: tokenPosition(14, 18, 1, 15, 1, 19)}}
            }])).toEqual([{
                command: 'SELECT',
                language: 'DML',
                operation: 'read',
                result: {columns: [{name: '*', content: {kind: 'wildcard'}}]},
                from: {table: {entity: 'users'}},
                joins: []
            }])
        })
    })
})
