import {describe, expect, test} from "@jest/globals";
import {safeJsonParse} from "./json";

describe('json', () => {
    test('safeJsonParse', () => {
        expect(safeJsonParse('bad')).toEqual('bad')
        expect(safeJsonParse('"string"')).toEqual('string')
        expect(safeJsonParse('1')).toEqual(1)
        expect(safeJsonParse('{"foo": "bar"}')).toEqual({foo: 'bar'})
    })
})
