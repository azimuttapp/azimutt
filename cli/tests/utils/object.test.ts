import {describe, expect, test} from "@jest/globals";
import {filterValues} from "../../src/utils/object";

describe('utils/object', () => {
    test('filterValues', () => {
        expect(filterValues({a: 1, b: 2, c: 3, d: 4}, v => v % 2 === 0)).toEqual({b: 2, d: 4})
    })
})
