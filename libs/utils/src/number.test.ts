import {describe, expect, test} from "@jest/globals";
import {strictParseInt} from "./number";

describe('number', () => {
    test('strictParseInt', () => {
        expect(strictParseInt('1')).toEqual(1)
        expect(() => strictParseInt('1.0')).toThrow(new Error('Not an integer.'))
        expect(() => strictParseInt('bad')).toThrow(new Error('Not an integer.'))
    })
})
