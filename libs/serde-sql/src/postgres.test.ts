import {describe, expect, test} from "@jest/globals";
import {tokenPosition} from "@azimutt/models";
import {parse} from "./chevrotain/parser";
import {SqlScriptAst} from "./chevrotain/ast";
import {format} from "./chevrotain/formatter";
import {SqlScript} from "./statements";

describe('postgres', () => {
    describe('select', () => {
        test('basic', () => {
            const query = 'SELECT * FROM users;'
            const ast: SqlScriptAst = [{
                command: 'SELECT',
                result: {columns: [
                        {column: {wildcard: '*', parser: tokenPosition(7, 7, 1, 8, 1, 8)}}
                    ]},
                from: {table: {identifier: 'users', parser: tokenPosition(14, 18, 1, 15, 1, 19)}}
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
