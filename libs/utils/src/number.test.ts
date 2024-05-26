import {describe, expect, test} from "@jest/globals";
import {prettyNumber, strictParseInt} from "./number";

describe('number', () => {
    test('prettyNumber', () => {
        expect(prettyNumber(0)).toEqual('0')
        expect(prettyNumber(0.1234)).toEqual('0.12')
        expect(prettyNumber(1.234)).toEqual('1.2')
        expect(prettyNumber(12.34)).toEqual('12')
        expect(prettyNumber(123.4)).toEqual('123')
    })
    test('strictParseInt', () => {
        expect(strictParseInt('1')).toEqual(1)
        expect(() => strictParseInt('1.0')).toThrow(new Error('Not an integer.'))
        expect(() => strictParseInt('bad')).toThrow(new Error('Not an integer.'))
    })
})
