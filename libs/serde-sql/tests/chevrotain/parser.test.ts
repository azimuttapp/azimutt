import {describe, expect, test} from "@jest/globals";
import {parse, parseRule} from "../../src/chevrotain/parser";

describe('chevrotain parser', () => {
    test('empty', () => {
        expect(parse('')).toEqual({result: []})
    })
    describe('select', () => {
        test('minimal', () => {
            expect(parse('SELECT * FROM users;')).toEqual({result: [{
                command: 'SELECT',
                result: {columns: [
                    {column: {wildcard: '*', parser: {token: 'Star', offset: [7, 7], line: [1, 1], column: [8, 8]}}}
                ]},
                from: {table: {identifier: 'users', parser: {token: 'Identifier', offset: [14, 18], line: [1, 1], column: [15, 19]}}}
            }]})
        })
        test('basic', () => {
            expect(parse('SELECT name FROM users WHERE id=1;')).toEqual({result: [{
                command: 'SELECT',
                result: {columns: [
                    {column: {identifier: 'name', parser: {token: 'Identifier', offset: [7, 10], line: [1, 1], column: [8, 11]}}}
                ]},
                from: {table: {identifier: 'users', parser: {token: 'Identifier', offset: [17, 21], line: [1, 1], column: [18, 22]}}},
                where: {
                    left: {column: {identifier: 'id', parser: {token: 'Identifier', offset: [29, 30], line: [1, 1], column: [30, 31]}}},
                    operation: {operator: '=', parser: {token: 'Equal', offset: [31, 31], line: [1, 1], column: [32, 32]}},
                    right: {value: 1, parser: {token: 'Integer', offset: [32, 32], line: [1, 1], column: [33, 33]}}
                }
            }]})
        })
        describe('result', () => {
            test('column', () => {
                expect(parseRule(p => p.selectResultRule(), 'SELECT id')).toEqual({result: {columns: [{column: {identifier: 'id', parser: {token: 'Identifier', offset: [7, 8], line: [1, 1], column: [8, 9]}}}]}})
                expect(parseRule(p => p.selectResultRule(), 'SELECT u.id')).toEqual({result: {columns: [{
                    column: {identifier: 'id', parser: {token: 'Identifier', offset: [9, 10], line: [1, 1], column: [10, 11]}},
                    table: {identifier: 'u', parser: {token: 'Identifier', offset: [7, 7], line: [1, 1], column: [8, 8]}},
                }]}})
                expect(parseRule(p => p.selectResultRule(), 'SELECT id, name')).toEqual({result: {columns: [
                    {column: {identifier: 'id', parser: {token: 'Identifier', offset: [7, 8], line: [1, 1], column: [8, 9]}}},
                    {column: {identifier: 'name', parser: {token: 'Identifier', offset: [11, 14], line: [1, 1], column: [12, 15]}}},
                ]}})
            })
            test('wildcard', () => {
                expect(parseRule(p => p.selectResultRule(), 'SELECT *')).toEqual({result: {columns: [{column: {wildcard: '*', parser: {token: 'Star', offset: [7, 7], line: [1, 1], column: [8, 8]}}}]}})
                expect(parseRule(p => p.selectResultRule(), 'SELECT u.*')).toEqual({result: {columns: [{
                    column: {wildcard: '*', parser: {token: 'Star', offset: [9, 9], line: [1, 1], column: [10, 10]}},
                    table: {identifier: 'u', parser: {token: 'Identifier', offset: [7, 7], line: [1, 1], column: [8, 8]}},
                }]}})
            })
            // TODO: alias, expressions
        })
        describe('from', () => {
            test('table', () => {
                expect(parseRule(p => p.selectFromRule(), 'FROM users')).toEqual({result: {table: {identifier: 'users', parser: {token: 'Identifier', offset: [5, 9], line: [1, 1], column: [6, 10]}}}})
            })
            test('schema', () => {
                expect(parseRule(p => p.selectFromRule(), 'FROM public.users')).toEqual({result: {
                    schema: {identifier: 'public', parser: {token: 'Identifier', offset: [5, 10], line: [1, 1], column: [6, 11]}},
                    table: {identifier: 'users', parser: {token: 'Identifier', offset: [12, 16], line: [1, 1], column: [13, 17]}}
                }})
            })
            // TODO: alias, joins
        })
        describe('where', () => {
            test('equal', () => {
                expect(parseRule(p => p.selectWhereRule(), 'WHERE id=1')).toEqual({result: {
                    left: {column: {identifier: 'id', parser: {token: 'Identifier', offset: [6, 7], line: [1, 1], column: [7, 8]}}},
                    operation: {operator: '=', parser: {token: 'Equal', offset: [8, 8], line: [1, 1], column: [9, 9]}},
                    right: {value: 1, parser: {token: 'Integer', offset: [9, 9], line: [1, 1], column: [10, 10]}}
                }})
            })
            test('not equal', () => {
                expect(parseRule(p => p.selectWhereRule(), "WHERE users.id != 'abc'")).toEqual({result: {
                    left: {
                        table: {identifier: 'users', parser: {token: 'Identifier', offset: [6, 10], line: [1, 1], column: [7, 11]}},
                        column: {identifier: 'id', parser: {token: 'Identifier', offset: [12, 13], line: [1, 1], column: [13, 14]}}
                    },
                    operation: {operator: '!=', parser: {token: 'NotEqual', offset: [15, 16], line: [1, 1], column: [16, 17]}},
                    right: {value: 'abc', parser: {token: 'String', offset: [18, 22], line: [1, 1], column: [19, 23]}},
                }})
            })
            test('less than', () => {
                expect(parseRule(p => p.selectWhereRule(), 'WHERE "public".users.id < 12')).toEqual({result: {
                    left: {
                        schema: {identifier: 'public', parser: {token: 'Identifier', offset: [6, 13], line: [1, 1], column: [7, 14]}},
                        table: {identifier: 'users', parser: {token: 'Identifier', offset: [15, 19], line: [1, 1], column: [16, 20]}},
                        column: {identifier: 'id', parser: {token: 'Identifier', offset: [21, 22], line: [1, 1], column: [22, 23]}}
                    },
                    operation: {operator: '<', parser: {token: 'LessThan', offset: [24, 24], line: [1, 1], column: [25, 25]}},
                    right: {value: 12, parser: {token: 'Integer', offset: [26, 27], line: [1, 1], column: [27, 28]}},
                }})
            })
            // TODO: IS NOT NULL, OR, AND
        })
    })
    describe.skip('create table', () => {
        test('basic', () => {
            const res = parse('CREATE TABLE users (id integer, name varchar);')
            console.log('res', res)
            expect(res).toEqual({result: [{
                command: 'CREATE_TABLE',
                table: {identifier: 'users', parser: {token: 'Identifier', offset: [13, 17], line: [1, 1], column: [14, 18]}},
                columns: [
                    {name: {identifier: 'id', parser: {token: 'Identifier', offset: [20, 21], line: [1, 1], column: [21, 22]}}, type: {identifier: 'integer', parser: {token: 'Identifier', offset: [23, 29], line: [1, 1], column: [24, 30]}}},
                    {name: {identifier: 'name', parser: {token: 'Identifier', offset: [31, 34], line: [1, 1], column: [32, 35]}}, type: {identifier: 'varchar', parser: {token: 'Identifier', offset: [36, 42], line: [1, 1], column: [37, 43]}}},
                ]
            }]})
        })
    })
    describe('common', () => {
        test('integerRule', () => {
            expect(parseRule(p => p.integerRule(), '12')).toEqual({result: {value: 12, parser: {token: 'Integer', offset: [0, 1], line: [1, 1], column: [1, 2]}}})
            expect(parseRule(p => p.integerRule(), 'bad')).toEqual({errors: [{name: 'MismatchedTokenException', message: "Expecting token of type --> Integer <-- but found --> 'bad' <--", position: {offset: [0, 2], line: [1, 1], column: [1, 3]}}]})
        })
        test('stringRule', () => {
            expect(parseRule(p => p.stringRule(), "'abc'")).toEqual({result: {value: 'abc', parser: {token: 'String', offset: [0, 4], line: [1, 1], column: [1, 5]}}})
            expect(parseRule(p => p.stringRule(), "'It\\'s'")).toEqual({result: {value: "It's", parser: {token: 'String', offset: [0, 6], line: [1, 1], column: [1, 7]}}})
            expect(parseRule(p => p.stringRule(), "bad")).toEqual({errors: [{name: 'MismatchedTokenException', message: "Expecting token of type --> String <-- but found --> 'bad' <--", position: {offset: [0, 2], line: [1, 1], column: [1, 3]}}]})
        })
        test('booleanRule', () => {
            expect(parseRule(p => p.booleanRule(), 'true')).toEqual({result: {value: true, parser: {token: 'Boolean', offset: [0, 3], line: [1, 1], column: [1, 4]}}})
            expect(parseRule(p => p.booleanRule(), 'false')).toEqual({result: {value: false, parser: {token: 'Boolean', offset: [0, 4], line: [1, 1], column: [1, 5]}}})
            expect(parseRule(p => p.booleanRule(), 'bad')).toEqual({errors: [{name: 'MismatchedTokenException', message: "Expecting token of type --> Boolean <-- but found --> 'bad' <--", position: {offset: [0, 2], line: [1, 1], column: [1, 3]}}]})
        })
        test('identifierRule', () => {
            expect(parseRule(p => p.identifierRule(), 'id')).toEqual({result: {identifier: 'id', parser: {token: 'Identifier', offset: [0, 1], line: [1, 1], column: [1, 2]}}})
            expect(parseRule(p => p.identifierRule(), '"my col"')).toEqual({result: {identifier: 'my col', parser: {token: 'Identifier', offset: [0, 7], line: [1, 1], column: [1, 8]}}})
            expect(parseRule(p => p.identifierRule(), '"my \\"new\\" col"')).toEqual({result: {identifier: 'my "new" col', parser: {token: 'Identifier', offset: [0, 15], line: [1, 1], column: [1, 16]}}})
            expect(parseRule(p => p.identifierRule(), 'bad col')).toEqual({errors: [{name: 'NotAllInputParsedException', message: "Redundant input, expecting EOF but found: col", position: {offset: [4, 6], line: [1, 1], column: [5, 7]}}]})
        })
        test('tableRefRule', () => {
            expect(parseRule(p => p.tableRefRule(), 'users')).toEqual({result: {table: {identifier: 'users', parser: {token: 'Identifier', offset: [0, 4], line: [1, 1], column: [1, 5]}}}})
            expect(parseRule(p => p.tableRefRule(), 'public.users')).toEqual({result: {
                table: {identifier: 'users', parser: {token: 'Identifier', offset: [7, 11], line: [1, 1], column: [8, 12]}},
                schema: {identifier: 'public', parser: {token: 'Identifier', offset: [0, 5], line: [1, 1], column: [1, 6]}},
            }})
        })
        test('columnRefRule', () => {
            expect(parseRule(p => p.columnRefRule(), 'id')).toEqual({result: {column: {identifier: 'id', parser: {token: 'Identifier', offset: [0, 1], line: [1, 1], column: [1, 2]}}}})
            expect(parseRule(p => p.columnRefRule(), 'users.id')).toEqual({result: {
                column: {identifier: 'id', parser: {token: 'Identifier', offset: [6, 7], line: [1, 1], column: [7, 8]}},
                table: {identifier: 'users', parser: {token: 'Identifier', offset: [0, 4], line: [1, 1], column: [1, 5]}}
            }})
            expect(parseRule(p => p.columnRefRule(), 'public.users.id')).toEqual({result: {
                column: {identifier: 'id', parser: {token: 'Identifier', offset: [13, 14], line: [1, 1], column: [14, 15]}},
                table: {identifier: 'users', parser: {token: 'Identifier', offset: [7, 11], line: [1, 1], column: [8, 12]}},
                schema: {identifier: 'public', parser: {token: 'Identifier', offset: [0, 5], line: [1, 1], column: [1, 6]}},
            }})
        })
        test('conditionOpRule', () => {
            expect(parseRule(p => p.conditionOpRule(), '=')).toEqual({result: {operator: '=', parser: {token: 'Equal', offset: [0, 0], line: [1, 1], column: [1, 1]}}})
            expect(parseRule(p => p.conditionOpRule(), '!=')).toEqual({result: {operator: '!=', parser: {token: 'NotEqual', offset: [0, 1], line: [1, 1], column: [1, 2]}}})
            expect(parseRule(p => p.conditionOpRule(), '<')).toEqual({result: {operator: '<', parser: {token: 'LessThan', offset: [0, 0], line: [1, 1], column: [1, 1]}}})
            expect(parseRule(p => p.conditionOpRule(), '>')).toEqual({result: {operator: '>', parser: {token: 'GreaterThan', offset: [0, 0], line: [1, 1], column: [1, 1]}}})
            expect(parseRule(p => p.conditionOpRule(), 'bad')).toEqual({errors: [{name: 'NoViableAltException', message: "Expecting: one of these possible Token sequences:\n  1. [Equal]\n  2. [NotEqual]\n  3. [LessThan]\n  4. [GreaterThan]\nbut found: 'bad'", position: {offset: [0, 2], line: [1, 1], column: [1, 3]}}]})
        })
        test('conditionElemRule', () => {
            expect(parseRule(p => p.conditionElemRule(), '12')).toEqual({result: {value: 12, parser: {token: 'Integer', offset: [0, 1], line: [1, 1], column: [1, 2]}}})
            expect(parseRule(p => p.conditionElemRule(), "'abc'")).toEqual({result: {value: 'abc', parser: {token: 'String', offset: [0, 4], line: [1, 1], column: [1, 5]}}})
            expect(parseRule(p => p.conditionElemRule(), 'true')).toEqual({result: {value: true, parser: {token: 'Boolean', offset: [0, 3], line: [1, 1], column: [1, 4]}}})
            expect(parseRule(p => p.conditionElemRule(), 'id')).toEqual({result: {column: {identifier: 'id', parser: {token: 'Identifier', offset: [0, 1], line: [1, 1], column: [1, 2]}}}})
            expect(parseRule(p => p.conditionElemRule(), '=')).toEqual({errors: [{name: 'NoViableAltException', message: "Expecting: one of these possible Token sequences:\n  1. [Integer]\n  2. [String]\n  3. [Boolean]\n  4. [Identifier]\nbut found: '='", position: {offset: [0, 0], line: [1, 1], column: [1, 1]}}]})
        })
        test('conditionRule', () => {
            expect(parseRule(p => p.conditionRule(), 'id<12')).toEqual({result: {
                left: {column: {identifier: 'id', parser: {token: 'Identifier', offset: [0, 1], line: [1, 1], column: [1, 2]}}},
                operation: {operator: '<', parser: {token: 'LessThan', offset: [2, 2], line: [1, 1], column: [3, 3]}},
                right: {value: 12, parser: {token: 'Integer', offset: [3, 4], line: [1, 1], column: [4, 5]}}
            }})
            expect(parseRule(p => p.conditionRule(), 'users."first name" = \'loic\'')).toEqual({result: {
                left: {
                    column: {identifier: 'first name', parser: {token: 'Identifier', offset: [6, 17], line: [1, 1], column: [7, 18]}},
                    table: {identifier: 'users', parser: {token: 'Identifier', offset: [0, 4], line: [1, 1], column: [1, 5]}}
                },
                operation: {operator: '=', parser: {token: 'Equal', offset: [19, 19], line: [1, 1], column: [20, 20]}},
                right: {value: 'loic', parser: {token: 'String', offset: [21, 26], line: [1, 1], column: [22, 27]}}
            }})
            expect(parseRule(p => p.conditionRule(), '=')).toEqual({errors: [{name: 'NoViableAltException', message: "Expecting: one of these possible Token sequences:\n  1. [Integer]\n  2. [String]\n  3. [Boolean]\n  4. [Identifier]\nbut found: '='", position: {offset: [0, 0], line: [1, 1], column: [1, 1]}}]})
        })
    })
})
