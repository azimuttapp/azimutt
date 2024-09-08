import {describe, expect, test} from "@jest/globals";
import {tokenPosition} from "@azimutt/models";
import {parse, parseRule} from "./parser";

describe('chevrotain parser', () => {
    test('empty', () => {
        expect(parse('')).toEqual({result: []})
    })
    describe('select', () => {
        test('minimal', () => {
            expect(parse('SELECT * FROM users;')).toEqual({result: [{
                command: 'SELECT',
                result: {columns: [
                    {column: {wildcard: '*', parser: tokenPosition(7, 7, 1, 8, 1, 8)}}
                ]},
                from: {table: {identifier: 'users', parser: tokenPosition(14, 18, 1, 15, 1, 19)}}
            }]})
        })
        test('basic', () => {
            expect(parse('SELECT name FROM users WHERE id=1;')).toEqual({result: [{
                command: 'SELECT',
                result: {columns: [
                    {column: {identifier: 'name', parser: tokenPosition(7, 10, 1, 8, 1, 11)}}
                ]},
                from: {table: {identifier: 'users', parser: tokenPosition(17, 21, 1, 18, 1, 22)}},
                where: {
                    left: {column: {identifier: 'id', parser: tokenPosition(29, 30, 1, 30, 1, 31)}},
                    operation: {operator: '=', parser: tokenPosition(31, 31, 1, 32, 1, 32)},
                    right: {value: 1, parser: tokenPosition(32, 32, 1, 33, 1, 33)}
                }
            }]})
        })
        describe('result', () => {
            test('column', () => {
                expect(parseRule(p => p.selectResultRule(), 'SELECT id')).toEqual({result: {columns: [{column: {identifier: 'id', parser: tokenPosition(7, 8, 1, 8, 1, 9)}}]}})
                expect(parseRule(p => p.selectResultRule(), 'SELECT u.id')).toEqual({result: {columns: [{
                    column: {identifier: 'id', parser: tokenPosition(9, 10, 1, 10, 1, 11)},
                    table: {identifier: 'u', parser: tokenPosition(7, 7, 1, 8, 1, 8)},
                }]}})
                expect(parseRule(p => p.selectResultRule(), 'SELECT id, name')).toEqual({result: {columns: [
                    {column: {identifier: 'id', parser: tokenPosition(7, 8, 1, 8, 1, 9)}},
                    {column: {identifier: 'name', parser: tokenPosition(11, 14, 1, 12, 1, 15)}},
                ]}})
            })
            test('wildcard', () => {
                expect(parseRule(p => p.selectResultRule(), 'SELECT *')).toEqual({result: {columns: [{column: {wildcard: '*', parser: tokenPosition(7, 7, 1, 8, 1, 8)}}]}})
                expect(parseRule(p => p.selectResultRule(), 'SELECT u.*')).toEqual({result: {columns: [{
                    column: {wildcard: '*', parser: tokenPosition(9, 9, 1, 10, 1, 10)},
                    table: {identifier: 'u', parser: tokenPosition(7, 7, 1, 8, 1, 8)},
                }]}})
            })
            // TODO: alias, expressions
        })
        describe('from', () => {
            test('table', () => {
                expect(parseRule(p => p.selectFromRule(), 'FROM users')).toEqual({result: {table: {identifier: 'users', parser: tokenPosition(5, 9, 1, 6, 1, 10)}}})
            })
            test('schema', () => {
                expect(parseRule(p => p.selectFromRule(), 'FROM public.users')).toEqual({result: {
                    schema: {identifier: 'public', parser: tokenPosition(5, 10, 1, 6, 1, 11)},
                    table: {identifier: 'users', parser: tokenPosition(12, 16, 1, 13, 1, 17)}
                }})
            })
            // TODO: alias, joins
        })
        describe('where', () => {
            test('equal', () => {
                expect(parseRule(p => p.selectWhereRule(), 'WHERE id=1')).toEqual({result: {
                    left: {column: {identifier: 'id', parser: tokenPosition(6, 7, 1, 7, 1, 8)}},
                    operation: {operator: '=', parser: tokenPosition(8, 8, 1, 9, 1, 9)},
                    right: {value: 1, parser: tokenPosition(9, 9, 1, 10, 1, 10)}
                }})
            })
            test('not equal', () => {
                expect(parseRule(p => p.selectWhereRule(), "WHERE users.id != 'abc'")).toEqual({result: {
                    left: {
                        table: {identifier: 'users', parser: tokenPosition(6, 10, 1, 7, 1, 11)},
                        column: {identifier: 'id', parser: tokenPosition(12, 13, 1, 13, 1, 14)}
                    },
                    operation: {operator: '!=', parser: tokenPosition(15, 16, 1, 16, 1, 17)},
                    right: {value: 'abc', parser: tokenPosition(18, 22, 1, 19, 1, 23)},
                }})
            })
            test('less than', () => {
                expect(parseRule(p => p.selectWhereRule(), 'WHERE "public".users.id < 12')).toEqual({result: {
                    left: {
                        schema: {identifier: 'public', parser: tokenPosition(6, 13, 1, 7, 1, 14)},
                        table: {identifier: 'users', parser: tokenPosition(15, 19, 1, 16, 1, 20)},
                        column: {identifier: 'id', parser: tokenPosition(21, 22, 1, 22, 1, 23)}
                    },
                    operation: {operator: '<', parser: tokenPosition(24, 24, 1, 25, 1, 25)},
                    right: {value: 12, parser: tokenPosition(26, 27, 1, 27, 1, 28)},
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
                table: {identifier: 'users', parser: tokenPosition(13, 17, 1, 14, 1, 18)},
                columns: [
                    {name: {identifier: 'id', parser: tokenPosition(20, 21, 1, 21, 1, 22)}, type: {identifier: 'integer', parser: tokenPosition(23, 29, 1, 24, 1, 30)}},
                    {name: {identifier: 'name', parser: tokenPosition(31, 34, 1, 32, 1, 35)}, type: {identifier: 'varchar', parser: tokenPosition(36, 42, 1, 37, 1, 43)}},
                ]
            }]})
        })
    })
    describe('common', () => {
        test('integerRule', () => {
            expect(parseRule(p => p.integerRule(), '12')).toEqual({result: {value: 12, parser: tokenPosition(0, 1, 1, 1, 1, 2)}})
            expect(parseRule(p => p.integerRule(), 'bad')).toEqual({errors: [{name: 'MismatchedTokenException', kind: 'error', message: "Expecting token of type --> Integer <-- but found --> 'bad' <--", ...tokenPosition(0, 2, 1, 1, 1, 3)}]})
        })
        test('stringRule', () => {
            expect(parseRule(p => p.stringRule(), "'abc'")).toEqual({result: {value: 'abc', parser: tokenPosition(0, 4, 1, 1, 1, 5)}})
            expect(parseRule(p => p.stringRule(), "'It\\'s'")).toEqual({result: {value: "It's", parser: tokenPosition(0, 6, 1, 1, 1, 7)}})
            expect(parseRule(p => p.stringRule(), "bad")).toEqual({errors: [{name: 'MismatchedTokenException', kind: 'error', message: "Expecting token of type --> String <-- but found --> 'bad' <--", ...tokenPosition(0, 2, 1, 1, 1, 3)}]})
        })
        test('booleanRule', () => {
            expect(parseRule(p => p.booleanRule(), 'true')).toEqual({result: {value: true, parser: tokenPosition(0, 3, 1, 1, 1, 4)}})
            expect(parseRule(p => p.booleanRule(), 'false')).toEqual({result: {value: false, parser: tokenPosition(0, 4, 1, 1, 1, 5)}})
            expect(parseRule(p => p.booleanRule(), 'bad')).toEqual({errors: [{name: 'MismatchedTokenException', kind: 'error', message: "Expecting token of type --> Boolean <-- but found --> 'bad' <--", ...tokenPosition(0, 2, 1, 1, 1, 3)}]})
        })
        test('identifierRule', () => {
            expect(parseRule(p => p.identifierRule(), 'id')).toEqual({result: {identifier: 'id', parser: tokenPosition(0, 1, 1, 1, 1, 2)}})
            expect(parseRule(p => p.identifierRule(), '"my col"')).toEqual({result: {identifier: 'my col', parser: tokenPosition(0, 7, 1, 1, 1, 8)}})
            expect(parseRule(p => p.identifierRule(), '"my \\"new\\" col"')).toEqual({result: {identifier: 'my "new" col', parser: tokenPosition(0, 15, 1, 1, 1, 16)}})
            expect(parseRule(p => p.identifierRule(), 'bad col')).toEqual({errors: [{name: 'NotAllInputParsedException', kind: 'error', message: "Redundant input, expecting EOF but found: col", ...tokenPosition(4, 6, 1, 5, 1, 7)}]})
        })
        test('tableRefRule', () => {
            expect(parseRule(p => p.tableRefRule(), 'users')).toEqual({result: {table: {identifier: 'users', parser: tokenPosition(0, 4, 1, 1, 1, 5)}}})
            expect(parseRule(p => p.tableRefRule(), 'public.users')).toEqual({result: {
                table: {identifier: 'users', parser: tokenPosition(7, 11, 1, 8, 1, 12)},
                schema: {identifier: 'public', parser: tokenPosition(0, 5, 1, 1, 1, 6)},
            }})
        })
        test('columnRefRule', () => {
            expect(parseRule(p => p.columnRefRule(), 'id')).toEqual({result: {column: {identifier: 'id', parser: tokenPosition(0, 1, 1, 1, 1, 2)}}})
            expect(parseRule(p => p.columnRefRule(), 'users.id')).toEqual({result: {
                column: {identifier: 'id', parser: tokenPosition(6, 7, 1, 7, 1, 8)},
                table: {identifier: 'users', parser: tokenPosition(0, 4, 1, 1, 1, 5)}
            }})
            expect(parseRule(p => p.columnRefRule(), 'public.users.id')).toEqual({result: {
                column: {identifier: 'id', parser: tokenPosition(13, 14, 1, 14, 1, 15)},
                table: {identifier: 'users', parser: tokenPosition(7, 11, 1, 8, 1, 12)},
                schema: {identifier: 'public', parser: tokenPosition(0, 5, 1, 1, 1, 6)},
            }})
        })
        test('conditionOpRule', () => {
            expect(parseRule(p => p.conditionOpRule(), '=')).toEqual({result: {operator: '=', parser: tokenPosition(0, 0, 1, 1, 1, 1)}})
            expect(parseRule(p => p.conditionOpRule(), '!=')).toEqual({result: {operator: '!=', parser: tokenPosition(0, 1, 1, 1, 1, 2)}})
            expect(parseRule(p => p.conditionOpRule(), '<')).toEqual({result: {operator: '<', parser: tokenPosition(0, 0, 1, 1, 1, 1)}})
            expect(parseRule(p => p.conditionOpRule(), '>')).toEqual({result: {operator: '>', parser: tokenPosition(0, 0, 1, 1, 1, 1)}})
            expect(parseRule(p => p.conditionOpRule(), 'bad')).toEqual({errors: [{name: 'NoViableAltException', kind: 'error', message: "Expecting: one of these possible Token sequences:\n  1. [Equal]\n  2. [NotEqual]\n  3. [LessThan]\n  4. [GreaterThan]\nbut found: 'bad'", ...tokenPosition(0, 2, 1, 1, 1, 3)}]})
        })
        test('conditionElemRule', () => {
            expect(parseRule(p => p.conditionElemRule(), '12')).toEqual({result: {value: 12, parser: tokenPosition(0, 1, 1, 1, 1, 2)}})
            expect(parseRule(p => p.conditionElemRule(), "'abc'")).toEqual({result: {value: 'abc', parser: tokenPosition(0, 4, 1, 1, 1, 5)}})
            expect(parseRule(p => p.conditionElemRule(), 'true')).toEqual({result: {value: true, parser: tokenPosition(0, 3, 1, 1, 1, 4)}})
            expect(parseRule(p => p.conditionElemRule(), 'id')).toEqual({result: {column: {identifier: 'id', parser: tokenPosition(0, 1, 1, 1, 1, 2)}}})
            expect(parseRule(p => p.conditionElemRule(), '=')).toEqual({errors: [{name: 'NoViableAltException', kind: 'error', message: "Expecting: one of these possible Token sequences:\n  1. [Integer]\n  2. [String]\n  3. [Boolean]\n  4. [Identifier]\nbut found: '='", ...tokenPosition(0, 0, 1, 1, 1, 1)}]})
        })
        test('conditionRule', () => {
            expect(parseRule(p => p.conditionRule(), 'id<12')).toEqual({result: {
                left: {column: {identifier: 'id', parser: tokenPosition(0, 1, 1, 1, 1, 2)}},
                operation: {operator: '<', parser: tokenPosition(2, 2, 1, 3, 1, 3)},
                right: {value: 12, parser: tokenPosition(3, 4, 1, 4, 1, 5)}
            }})
            expect(parseRule(p => p.conditionRule(), 'users."first name" = \'loic\'')).toEqual({result: {
                left: {
                    column: {identifier: 'first name', parser: tokenPosition(6, 17, 1, 7, 1, 18)},
                    table: {identifier: 'users', parser: tokenPosition(0, 4, 1, 1, 1, 5)}
                },
                operation: {operator: '=', parser: tokenPosition(19, 19, 1, 20, 1, 20)},
                right: {value: 'loic', parser: tokenPosition(21, 26, 1, 22, 1, 27)}
            }})
            expect(parseRule(p => p.conditionRule(), '=')).toEqual({errors: [{name: 'NoViableAltException', kind: 'error', message: "Expecting: one of these possible Token sequences:\n  1. [Integer]\n  2. [String]\n  3. [Boolean]\n  4. [Identifier]\nbut found: '='", ...tokenPosition(0, 0, 1, 1, 1, 1)}]})
        })
    })
})
