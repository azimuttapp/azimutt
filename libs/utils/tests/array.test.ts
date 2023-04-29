import {describe, expect, test} from "@jest/globals";
import {distinct, groupBy, shuffle, zip} from "../src";

describe('array', () => {
    test('distinct', () => {
        expect(distinct([1, 1, 2, 3, 5, 3])).toEqual([1, 2, 3, 5])
    })
    test('groupBy', () => {
        expect(groupBy([1, 2, 3], i => i % 2)).toEqual({0: [2], 1: [1, 3]})
    })
    test('shuffle', () => {
        // use long array to reduce the probability to have the same one after shuffle ^^
        const array = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19]
        const shuffled = shuffle(array)
        expect(shuffled).not.toEqual(array)
        expect(shuffled.sort()).toEqual(array.sort())
    })
    test('zip', () => {
        expect(zip([1, 2, 3], ['a', 'b', 'c'])).toEqual([[1, 'a'], [2, 'b'], [3, 'c']])
        expect(zip([1, 2], ['a', 'b', 'c'])).toEqual([[1, 'a'], [2, 'b']])
        expect(zip([1, 2, 3], ['a', 'b'])).toEqual([[1, 'a'], [2, 'b']])
    })
})
