import {describe, expect, test} from "@jest/globals";
import {indent, removeSurroundingParentheses, stripIndent} from "../src";

describe('string', () => {
    test('indent', () => {
        expect(indent('some text')).toEqual('  some text')
        expect(indent(`
          my text
        `)).toEqual('  \n            my text\n          ')
    })
    test('removeSurroundingParentheses', () => {
        expect(removeSurroundingParentheses('some text')).toEqual('some text')
        expect(removeSurroundingParentheses('some (text)')).toEqual('some (text)')
        expect(removeSurroundingParentheses('(some text)')).toEqual('some text')
        expect(removeSurroundingParentheses('(some (text))')).toEqual('some (text)')
        expect(removeSurroundingParentheses('((some text))')).toEqual('some text')
    })
    test('stripIndent', () => {
        expect(stripIndent('some text')).toEqual('some text')
        expect(stripIndent(`
            my text
        `)).toEqual('my text')
        expect(stripIndent(`
            # title

            content
        `)).toEqual('# title\n\ncontent')
        expect(stripIndent(`
            # title

          content
        `)).toEqual('  # title\n\ncontent')
        expect(stripIndent('\nfoo\r\nbar\n')).toEqual('foo\r\nbar')
    })
})
