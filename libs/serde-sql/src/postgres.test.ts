import {describe, expect, test} from "@jest/globals";
import {parse} from "./chevrotain/parser";
import {SqlScriptAst} from "./chevrotain/ast";
import {SqlScript} from "./statements";
import {format} from "./chevrotain/formatter";

describe('postgres', () => {
    describe('select', () => {
        test('basic', () => {
            const query = 'SELECT * FROM users;'
            const ast: SqlScriptAst = [{
                command: 'SELECT',
                result: {columns: [
                        {column: {wildcard: '*', parser: {token: 'Star', offset: [7, 7], line: [1, 1], column: [8, 8]}}}
                    ]},
                from: {table: {identifier: 'users', parser: {token: 'Identifier', offset: [14, 18], line: [1, 1], column: [15, 19]}}}
            }]
            const statements: SqlScript = [{
                command: 'SELECT',
                language: 'DML',
                operation: 'read',
                result: {columns: [{name: '*', content: {kind: 'wildcard'}}]},
                from: {table: {entity: 'users'}},
                joins: []
            }]

            expect(parse(query)).toEqual({result: ast})
            expect(format(ast)).toEqual(statements)
        })
    })
})
