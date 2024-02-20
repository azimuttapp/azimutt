import {describe, expect, test} from "@jest/globals";
import {parseRule} from "../src/parser";

describe('aml parser', () => {
    /*test('empty', () => {
        expect(parse('')).toEqual({result: []})
    })*/
    describe('entity', () => {

    })
    describe('relation', () => {

    })
    describe('type', () => {

    })
    describe('common', () => {
        test('integerRule', () => {
            expect(parseRule(p => p.integerRule(), '12')).toEqual({result: {value: 12, parser: {token: 'Integer', offset: [0, 1], line: [1, 1], column: [1, 2]}}})
            expect(parseRule(p => p.integerRule(), 'bad')).toEqual({errors: [{kind: 'MismatchedTokenException', message: "Expecting token of type --> Integer <-- but found --> 'bad' <--", offset: [0, 2], line: [1, 1], column: [1, 3]}]})
        })
        test('identifierRule', () => {
            expect(parseRule(p => p.identifierRule(), 'id')).toEqual({result: {identifier: 'id', parser: {token: 'Identifier', offset: [0, 1], line: [1, 1], column: [1, 2]}}})
            expect(parseRule(p => p.identifierRule(), '"my col"')).toEqual({result: {identifier: 'my col', parser: {token: 'Identifier', offset: [0, 7], line: [1, 1], column: [1, 8]}}})
            expect(parseRule(p => p.identifierRule(), '"my \\"new\\" col"')).toEqual({result: {identifier: 'my "new" col', parser: {token: 'Identifier', offset: [0, 15], line: [1, 1], column: [1, 16]}}})
            expect(parseRule(p => p.identifierRule(), 'bad col')).toEqual({errors: [{kind: 'NotAllInputParsedException', message: "Redundant input, expecting EOF but found: col", offset: [4, 6], line: [1, 1], column: [5, 7]}]})
        })
        test('commentRule', () => {
            expect(parseRule(p => p.commentRule(), '# a comment')).toEqual({result: {comment: 'a comment', parser: {token: 'Comment', offset: [0, 10], line: [1, 1], column: [1, 11]}}})
            expect(parseRule(p => p.commentRule(), 'bad')).toEqual({errors: [{kind: 'MismatchedTokenException', message: "Expecting token of type --> Comment <-- but found --> 'bad' <--", offset: [0, 2], line: [1, 1], column: [1, 3]}]})
        })
        test('noteRule', () => {
            expect(parseRule(p => p.noteRule(), '| a note')).toEqual({result: {note: 'a note', parser: {token: 'Note', offset: [0, 7], line: [1, 1], column: [1, 8]}}})
            expect(parseRule(p => p.noteRule(), 'bad')).toEqual({errors: [{kind: 'MismatchedTokenException', message: "Expecting token of type --> Note <-- but found --> 'bad' <--", offset: [0, 2], line: [1, 1], column: [1, 3]}]})
        })
        test('propertiesRule', () => {
            expect(parseRule(p => p.propertiesRule(), '{}')).toEqual({result: []})
            expect(parseRule(p => p.propertiesRule(), '{flag}')).toEqual({result: [{key: {identifier: 'flag', parser: {token: 'Identifier', offset: [1, 4], line: [1, 1], column: [2, 5]}}}]})
            expect(parseRule(p => p.propertiesRule(), '{color: red}')).toEqual({result: [{
                key: {identifier: 'color', parser: {token: 'Identifier', offset: [1, 5], line: [1, 1], column: [2, 6]}},
                value: {identifier: 'red', parser: {token: 'Identifier', offset: [8, 10], line: [1, 1], column: [9, 11]}}
            }]})
            expect(parseRule(p => p.propertiesRule(), '{size: 12}')).toEqual({result: [{
                key: {identifier: 'size', parser: {token: 'Identifier', offset: [1, 4], line: [1, 1], column: [2, 5]}},
                value: {value: 12, parser: {token: 'Integer', offset: [7, 8], line: [1, 1], column: [8, 9]}}
            }]})
        })
    })
})
