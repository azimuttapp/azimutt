import {describe, expect, test} from "@jest/globals";
import {ParserResult} from "../../src";

describe('serde', () => {
    test('ParserResult', () => {
        expect(ParserResult.success(1).map(i => i + 1).result).toEqual(2)
        expect(ParserResult.failure<number>([]).map(i => i + 1).result).toEqual(undefined)
    })
})
