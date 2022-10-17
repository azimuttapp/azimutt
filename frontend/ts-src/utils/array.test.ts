import {groupBy} from "./array";

describe('array', () => {
    test('groupBy', () => {
        expect(groupBy([1, 2, 3, 4, 5], i => i % 2)).toEqual({0: [2, 4], 1: [1, 3, 5]})
    })
})
