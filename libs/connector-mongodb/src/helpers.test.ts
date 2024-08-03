import {describe, expect, test} from "@jest/globals";
import {scopeFilter} from "./helpers";

describe('helpers', () => {
    test('scopeFilter', () => {
        expect(scopeFilter({}, {})).toEqual(true)
        expect(scopeFilter({database: 'db'}, {})).toEqual(true)
        expect(scopeFilter({database: 'local'}, {})).toEqual(false)
        expect(scopeFilter({database: 'db'}, {database: 'db'})).toEqual(true)
        expect(scopeFilter({database: 'local'}, {database: 'local'})).toEqual(true)
        expect(scopeFilter({database: 'other'}, {database: 'db'})).toEqual(false)
        // TODO expect(scopeFilter({database: 'other'}, {database: '!db'})).toEqual(true)
        expect(scopeFilter({database: 'az_test'}, {database: 'az_%'})).toEqual(true)
        expect(scopeFilter({database: 'local'}, {database: 'az_%'})).toEqual(false)
        // TODO expect(scopeFilter({database: 'local'}, {database: '!az_%'})).toEqual(true)
    })
})
