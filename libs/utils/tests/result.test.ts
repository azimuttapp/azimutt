import {describe, expect, test} from "@jest/globals";
import {Result} from "../src";

describe('result', () => {
    test('map', () => {
        expect(Result.success(1).map(i => i + 1).result).toEqual(2)
        expect(Result.failure([]).map(i => i + 1).result).toEqual(undefined)
    })
    test('flatMap', () => {
        expect(Result.success(1).flatMap(i => Result.success(i + 1)).result).toEqual(2)
    })
})
