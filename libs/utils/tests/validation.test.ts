import {describe, expect, test} from "@jest/globals";
import {isEmpty, isObject} from "../src/validation";

describe('validation', () => {
    test('isEmpty', () => {
        expect(isEmpty(undefined)).toEqual(true)
        expect(isEmpty(null)).toEqual(true)
        expect(isEmpty(0)).toEqual(false)
        expect(isEmpty(1)).toEqual(false)
        expect(isEmpty('')).toEqual(true)
        expect(isEmpty('a')).toEqual(false)
        expect(isEmpty(true)).toEqual(false)
        expect(isEmpty(false)).toEqual(false)
        expect(isEmpty([])).toEqual(true)
        expect(isEmpty([1])).toEqual(false)
        expect(isEmpty({})).toEqual(true)
        expect(isEmpty({a: 1})).toEqual(false)
    })
    test('isObject', () => {
        expect(isObject({})).toEqual(true)
        expect(isObject([])).toEqual(false)
        expect(isObject(null)).toEqual(false)
        expect(isObject(undefined)).toEqual(false)
        expect(isObject('')).toEqual(false)
        expect(isObject(0)).toEqual(false)
        expect(isObject(true)).toEqual(false)
    })
})
