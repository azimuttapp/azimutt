import {describe, expect, test} from "@jest/globals";
import {
    compatibleCases,
    dateFromIsoFilename,
    dateToIsoFilename,
    indent,
    isCamelLower,
    isCamelUpper,
    isKebabLower,
    isKebabUpper,
    isSnakeLower,
    isSnakeUpper,
    joinLast,
    joinLimit,
    maxLen,
    parseUuid,
    pathJoin,
    pathParent,
    plural,
    removeSurroundingParentheses,
    singular,
    slugify,
    slugifyGitHub,
    splitWords,
    stringIsFloat,
    stringIsInt,
    stringIsISODate,
    stringIsUuid,
    stripIndent
} from "./string";

describe('string', () => {
    test('dateToIsoFilename', () => {
        const d = new Date(1716456672960)
        expect(dateToIsoFilename(d)).toEqual('2024-05-23T09-31-12-960Z')
        expect(dateFromIsoFilename('2024-05-23T09-31-12-960Z')).toEqual(d)
        expect(() => dateFromIsoFilename('bad')).toThrow(new Error('Invalid filename iso date: bad'))
    })
    test('indent', () => {
        expect(indent('some text')).toEqual('  some text')
        expect(indent(`
          my text
        `)).toEqual('  \n            my text\n          ')
    })
    test('isCamelUpper', () => {
        expect(isCamelUpper('AzimuttIsAwesome')).toBeTruthy()
        expect(isCamelUpper('azimuttIsAwesome')).toBeFalsy()
        expect(isCamelUpper('AZIMUTT_IS_AWESOME')).toBeFalsy()
        expect(isCamelUpper('azimutt_is_awesome')).toBeFalsy()
        expect(isCamelUpper('AZIMUTT-IS-AWESOME')).toBeFalsy()
        expect(isCamelUpper('azimutt-is-awesome')).toBeFalsy()
    })
    test('isCamelLower', () => {
        expect(isCamelLower('AzimuttIsAwesome')).toBeFalsy()
        expect(isCamelLower('azimuttIsAwesome')).toBeTruthy()
        expect(isCamelLower('AZIMUTT_IS_AWESOME')).toBeFalsy()
        expect(isCamelLower('azimutt_is_awesome')).toBeFalsy()
        expect(isCamelLower('AZIMUTT-IS-AWESOME')).toBeFalsy()
        expect(isCamelLower('azimutt-is-awesome')).toBeFalsy()
    })
    test('isSnakeUpper', () => {
        expect(isSnakeUpper('AzimuttIsAwesome')).toBeFalsy()
        expect(isSnakeUpper('azimuttIsAwesome')).toBeFalsy()
        expect(isSnakeUpper('AZIMUTT_IS_AWESOME')).toBeTruthy()
        expect(isSnakeUpper('AZIMUTT_IS_AWESOME_2')).toBeTruthy()
        expect(isSnakeUpper('azimutt_is_awesome')).toBeFalsy()
        expect(isSnakeUpper('AZIMUTT-IS-AWESOME')).toBeFalsy()
        expect(isSnakeUpper('azimutt-is-awesome')).toBeFalsy()
    })
    test('isSnakeLower', () => {
        expect(isSnakeLower('AzimuttIsAwesome')).toBeFalsy()
        expect(isSnakeLower('azimuttIsAwesome')).toBeFalsy()
        expect(isSnakeLower('AZIMUTT_IS_AWESOME')).toBeFalsy()
        expect(isSnakeLower('azimutt_is_awesome')).toBeTruthy()
        expect(isSnakeLower('azimutt_is_awesome_2')).toBeTruthy()
        expect(isSnakeLower('AZIMUTT-IS-AWESOME')).toBeFalsy()
        expect(isSnakeLower('azimutt-is-awesome')).toBeFalsy()
    })
    test('isKebabUpper', () => {
        expect(isKebabUpper('AzimuttIsAwesome')).toBeFalsy()
        expect(isKebabUpper('azimuttIsAwesome')).toBeFalsy()
        expect(isKebabUpper('AZIMUTT_IS_AWESOME')).toBeFalsy()
        expect(isKebabUpper('azimutt_is_awesome')).toBeFalsy()
        expect(isKebabUpper('AZIMUTT-IS-AWESOME')).toBeTruthy()
        expect(isKebabUpper('AZIMUTT-IS-AWESOME-2')).toBeTruthy()
        expect(isKebabUpper('azimutt-is-awesome')).toBeFalsy()
    })
    test('isKebabLower', () => {
        expect(isKebabLower('AzimuttIsAwesome')).toBeFalsy()
        expect(isKebabLower('azimuttIsAwesome')).toBeFalsy()
        expect(isKebabLower('AZIMUTT_IS_AWESOME')).toBeFalsy()
        expect(isKebabLower('azimutt_is_awesome')).toBeFalsy()
        expect(isKebabLower('AZIMUTT-IS-AWESOME')).toBeFalsy()
        expect(isKebabLower('azimutt-is-awesome')).toBeTruthy()
        expect(isKebabLower('azimutt-is-awesome-2')).toBeTruthy()
    })
    test('compatibleCases', () => {
        expect(compatibleCases('AzimuttIsAwesome')).toEqual(['camel-upper'])
        expect(compatibleCases('azimuttIsAwesome')).toEqual(['camel-lower'])
        expect(compatibleCases('AZIMUTT_IS_AWESOME')).toEqual(['snake-upper'])
        expect(compatibleCases('azimutt_is_awesome')).toEqual(['snake-lower'])
        expect(compatibleCases('AZIMUTT-IS-AWESOME')).toEqual(['kebab-upper'])
        expect(compatibleCases('azimutt-is-awesome')).toEqual(['kebab-lower'])
        expect(compatibleCases('AZ')).toEqual(['camel-upper', 'snake-upper', 'kebab-upper'])
        expect(compatibleCases('az')).toEqual(['camel-lower', 'snake-lower', 'kebab-lower'])
        expect(compatibleCases('some text')).toEqual([])
    })
    test('joinLast', () => {
        expect(joinLast([])).toEqual('')
        expect(joinLast(['a'])).toEqual('a')
        expect(joinLast(['a', 'b'])).toEqual('a and b')
        expect(joinLast(['a', 'b', 'c'])).toEqual('a, b and c')
        expect(joinLast(['a', 'b', 'c', 'd'])).toEqual('a, b, c and d')
    })
    test('joinLimit', () => {
        expect(joinLimit([])).toEqual('')
        expect(joinLimit(['a'])).toEqual('a')
        expect(joinLimit(['a', 'b'])).toEqual('a, b')
        expect(joinLimit(['a', 'b', 'c'])).toEqual('a, b, c')
        expect(joinLimit(['a', 'b', 'c', 'd'])).toEqual('a, b, c, d')
        expect(joinLimit(['a', 'b', 'c', 'd', 'e'])).toEqual('a, b, c, d, e')
        expect(joinLimit(['a', 'b', 'c', 'd', 'e', 'f'])).toEqual('a, b, c, d, e ...')
        expect(joinLimit(['a', 'b', 'c', 'd', 'e', 'f', 'g'])).toEqual('a, b, c, d, e ...')
    })
    test('maxLen', () => {
        expect(maxLen('a', 5)).toEqual('a')
        expect(maxLen('ab', 5)).toEqual('ab')
        expect(maxLen('abc', 5)).toEqual('abc')
        expect(maxLen('abcd', 5)).toEqual('abcd')
        expect(maxLen('abcde', 5)).toEqual('abcde')
        expect(maxLen('abcdef', 5)).toEqual('ab...')
        expect(maxLen('abcdef', 4)).toEqual('a...')
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
        // expect(pathJoin('./doc9/a/b/c/d', '../../../../aml.md')).toEqual('./doc9/aml.md') // many parents
        expect(pathJoin('./doc10///a/b', '../../aml.md')).toEqual('./doc10/aml.md') // repeating /
        expect(pathJoin('~/doc11/a', 'b')).toEqual('~/doc11/a/b') // home
        // TODO: absolute paths
    })
    test('pathParent', () => {
        expect(pathParent('./docs/README.md')).toEqual('./docs')
        expect(pathParent('./README.md')).toEqual('./')
        expect(pathParent('./docs/folder')).toEqual('./docs')
        expect(pathParent('./docs/folder/')).toEqual('./docs')
        expect(pathParent('./')).toEqual('./')
        expect(pathParent('~/docs/hello.json')).toEqual('~/docs')
    })
    test('plural', () => {
        expect(plural('cat')).toEqual('cats')
        expect(plural('bus')).toEqual('buses')
        expect(plural('index')).toEqual('indexes')
        expect(plural('blitz')).toEqual('blitzes')
        expect(plural('marsh')).toEqual('marshes')
        expect(plural('lunch')).toEqual('lunches')
        expect(plural('try')).toEqual('tries')
        expect(plural('ray')).toEqual('rays')
        expect(plural('boy')).toEqual('boys')
    })
    test('removeSurroundingParentheses', () => {
        expect(removeSurroundingParentheses('some text')).toEqual('some text')
        expect(removeSurroundingParentheses('some (text)')).toEqual('some (text)')
        expect(removeSurroundingParentheses('(some text)')).toEqual('some text')
        expect(removeSurroundingParentheses('(some (text))')).toEqual('some (text)')
        expect(removeSurroundingParentheses('((some text))')).toEqual('some text')
    })
    test('singular', () => {
        expect(singular('cats')).toEqual('cat')
        expect(singular('buses')).toEqual('bus')
        expect(singular('indexes')).toEqual('index')
        expect(singular('blitzes')).toEqual('blitz')
        expect(singular('marshes')).toEqual('marsh')
        expect(singular('lunches')).toEqual('lunch')
        expect(singular('tries')).toEqual('try')
        expect(singular('rays')).toEqual('ray')
        expect(singular('boys')).toEqual('boy')
        expect(singular('profiles')).toEqual('profile')
    })
    test('slugify', () => {
        expect(slugify('')).toEqual('')
        expect(slugify('Loïc Knuchel')).toEqual('loic-knuchel')
        expect(slugify('- Long   text, génial slug!')).toEqual('long-text-genial-slug')
        expect(slugify('🔖 Philosophy & Conventions')).toEqual('philosophy-conventions')
    })
    test('slugifyGitHub', () => {
        expect(slugifyGitHub('🔖 Philosophy & Conventions')).toEqual('-philosophy--conventions')
    })
    test('splitWords', () => {
        expect(splitWords('')).toEqual([])
        expect(splitWords('azimutt')).toEqual(['azimutt'])
        expect(splitWords('AZIMUTT')).toEqual(['azimutt'])
        expect(splitWords('Azimutt is awesome')).toEqual(['azimutt', 'is', 'awesome'])
        expect(splitWords('AzimuttIsAwesome')).toEqual(['azimutt', 'is', 'awesome'])
        expect(splitWords('azimuttIsAwesome')).toEqual(['azimutt', 'is', 'awesome'])
        expect(splitWords('AZIMUTT_IS_AWESOME')).toEqual(['azimutt', 'is', 'awesome'])
        expect(splitWords('azimutt_is_awesome')).toEqual(['azimutt', 'is', 'awesome'])
        expect(splitWords('AZIMUTT-IS-AWESOME')).toEqual(['azimutt', 'is', 'awesome'])
        expect(splitWords('azimutt-is-awesome')).toEqual(['azimutt', 'is', 'awesome'])
        expect(splitWords('[Azimutt, is awesome!]')).toEqual(['azimutt', 'is', 'awesome'])
    })
    test('stringIsInt', () => {
        expect(stringIsInt('1')).toBeTruthy()
        expect(stringIsInt('12')).toBeTruthy()
        expect(stringIsInt('1.2')).toBeFalsy()
        expect(stringIsInt('a')).toBeFalsy()
    })
    test('stringIsFloat', () => {
        expect(stringIsFloat('1')).toBeTruthy()
        expect(stringIsFloat('12')).toBeTruthy()
        expect(stringIsFloat('1.2')).toBeTruthy()
        expect(stringIsFloat('a')).toBeFalsy()
    })
    test('stringIsISODate', () => {
        expect(stringIsISODate('2024-05-30T09:49:58.068Z')).toBeTruthy()
        expect(stringIsISODate('0000-00-00T00:00:00.000Z')).toBeTruthy()
        expect(stringIsISODate('9999-99-99T99:99:99.999Z')).toBeFalsy()
        expect(stringIsISODate('a')).toBeFalsy()
    })
    test('stringIsUuid', () => {
        expect(stringIsUuid('123e4567-e89b-12d3-a456-426614174000')).toBeTruthy()
        expect(stringIsUuid('00000000-0000-0000-0000-000000000000')).toBeTruthy()
        expect(stringIsUuid('g0000000-0000-0000-0000-000000000000')).toBeFalsy()
        expect(stringIsUuid('a')).toBeFalsy()
    })
    test('parseUuid', () => {
        expect(parseUuid('c4f39518-1e6c-11ef-9262-0242ac120002')).toEqual({version: '1', variant: '9'}) // use time & mac address
        expect(parseUuid('000003e8-1e6d-21ef-a900-325096b39f47')).toEqual({version: '2', variant: 'a'}) // use time, mac address, user & group ids
        expect(parseUuid('b6602c76-f86e-32a2-ab42-71dd055ad3cc')).toEqual({version: '3', variant: 'a'}) // md5 hash of namespace & name
        expect(parseUuid('6deea181-0a25-4a9d-b860-cec2e2f543e2')).toEqual({version: '4', variant: 'b'}) // fully random
        expect(parseUuid('c952ea7d-b473-56da-8d80-0554dcb636fa')).toEqual({version: '5', variant: '8'}) // sha1 hash of namespace & name
        expect(parseUuid('018fc8fa-8f5b-766b-ad46-6b1b0d8a4e2d')).toEqual({version: '7', variant: 'a'}) // use time, counter & random
        expect(parseUuid('a')).toEqual({version: undefined, variant: undefined})
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
        expect(stripIndent('SELECT\n  name\nFROM users;')).toEqual('SELECT\n  name\nFROM users;')
    })
})
