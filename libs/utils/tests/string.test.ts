import {describe, expect, test} from "@jest/globals";
import {indent, pathJoin, pathParent, removeSurroundingParentheses, slugify, stripIndent} from "../src";

describe('string', () => {
    test('indent', () => {
        expect(indent('some text')).toEqual('  some text')
        expect(indent(`
          my text
        `)).toEqual('  \n            my text\n          ')
    })
    test('pathJoin', () => {
        expect(pathJoin()).toEqual('./')
        expect(pathJoin('')).toEqual('./')
        expect(pathJoin('.')).toEqual('./')
        expect(pathJoin('./')).toEqual('./')
        expect(pathJoin('./doc0')).toEqual('./doc0')
        expect(pathJoin('./doc1', '')).toEqual('./doc1') // add nothing
        expect(pathJoin('./doc2', '.')).toEqual('./doc2') // add current
        expect(pathJoin('./doc3', './')).toEqual('./doc3') // add current
        expect(pathJoin('./doc4', 'aml.md')).toEqual('./doc4/aml.md') // add `/` between
        expect(pathJoin('./doc5', './aml.md')).toEqual('./doc5/aml.md') // remove local start
        expect(pathJoin('./doc6/a', '../aml.md')).toEqual('./doc6/aml.md') // work with parent
        expect(pathJoin('./doc7/a/b', '../../aml.md')).toEqual('./doc7/aml.md') // work with several parents
        expect(pathJoin('./doc8', '../../aml.md')).toEqual('../aml.md') // keep parent when can't remove it
    })
    test('pathParent', () => {
        expect(pathParent('./docs/README.md')).toEqual('./docs')
        expect(pathParent('./README.md')).toEqual('.')
        expect(pathParent('./')).toEqual('.')
    })
    test('removeSurroundingParentheses', () => {
        expect(removeSurroundingParentheses('some text')).toEqual('some text')
        expect(removeSurroundingParentheses('some (text)')).toEqual('some (text)')
        expect(removeSurroundingParentheses('(some text)')).toEqual('some text')
        expect(removeSurroundingParentheses('(some (text))')).toEqual('some (text)')
        expect(removeSurroundingParentheses('((some text))')).toEqual('some text')
    })
    test('slugify', () => {
        expect(slugify('')).toEqual('')
        expect(slugify('Loïc Knuchel')).toEqual('loic-knuchel')
        expect(slugify('- Long   text, génial slug!')).toEqual('long-text-genial-slug')
        expect(slugify('🔖 Philosophy & Conventions')).toEqual('philosophy-conventions')
        expect(slugify('🔖 Philosophy & Conventions', {mode: 'github'})).toEqual('-philosophy--conventions')
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
