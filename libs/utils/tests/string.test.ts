import {describe, expect, test} from "@jest/globals";
import {removeSurroundingParentheses} from "../src";

describe('string', () => {
    test('removeSurroundingParentheses', () => {
        expect(removeSurroundingParentheses('some text')).toEqual('some text')
        expect(removeSurroundingParentheses('some (text)')).toEqual('some (text)')
        expect(removeSurroundingParentheses('(some text)')).toEqual('some text')
        expect(removeSurroundingParentheses('(some (text))')).toEqual('some (text)')
        expect(removeSurroundingParentheses('((some text))')).toEqual('some text')
    })
})
