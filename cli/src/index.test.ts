import {describe, expect, test} from "@jest/globals";

// to have at least one test in every module ^^
describe('index', () => {
    test('dummy', () => {
        expect(1 + 1).toEqual(2)
    })
})
