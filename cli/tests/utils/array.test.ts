import {describe, expect, test} from "@jest/globals";
import {groupBy, zip} from "../../src/utils/array";

describe('utils/array', () => {
    test('groupBy', () => {
        expect(groupBy([1, 2, 3], i => i % 2)).toEqual({0: [2], 1: [1, 3]})
    })
    test('zip', () => {
        expect(zip([1, 2, 3], ['a', 'b', 'c'])).toEqual([[1, 'a'], [2, 'b'], [3, 'c']])
        expect(zip([1, 2], ['a', 'b', 'c'])).toEqual([[1, 'a'], [2, 'b']])
        expect(zip([1, 2, 3], ['a', 'b'])).toEqual([[1, 'a'], [2, 'b']])
    })
})
