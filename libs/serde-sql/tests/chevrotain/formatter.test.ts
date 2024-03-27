import {describe, expect, test} from "@jest/globals";
import {format} from "../../src/chevrotain/formatter";

describe('chevrotain formatter', () => {
    test('empty', () => {
        expect(format([])).toEqual([])
    })
    describe('select', () => {
        test('basic', () => {
            expect(format([{
                command: 'SELECT',
                result: {columns: [
                    {column: {wildcard: '*', parser: {token: 'Star', offset: [7, 7], line: [1, 1], column: [8, 8]}}}
                ]},
                from: {table: {identifier: 'users', parser: {token: 'Identifier', offset: [14, 18], line: [1, 1], column: [15, 19]}}}
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
