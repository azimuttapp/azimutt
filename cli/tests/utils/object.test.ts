import {describe, expect, test} from "@jest/globals";
import {filterValues, mapValues} from "../../src/utils/object";

describe('utils/object', () => {
    test('mapValues', () => {
        expect(mapValues({a: 'luc', b: 'jean'}, v => v.length)).toEqual({a: 3, b: 4})
    })
    test('filterValues', () => {
        expect(filterValues({a: 1, b: 2, c: 3, d: 4}, v => v % 2 === 0)).toEqual({b: 2, d: 4})
    })
})
