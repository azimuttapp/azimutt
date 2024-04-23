import {describe, expect, test} from "@jest/globals";
import {limitDepth, getValueDeep} from "./any";

describe('any', () => {
    test('getValueDeep', () => {
        expect(getValueDeep({name: 'loic'}, ['name'])).toEqual('loic')
        expect(getValueDeep({tables: [{name: 'users'}]}, ['tables', 0, 'name'])).toEqual('users')
    })
    describe('limitDepth', () => {
        test('nested objects', () => {
            expect(limitDepth({db: 'azimutt', tables: [{name: 'users'}]}, 0)).toEqual('...')
            expect(limitDepth({db: 'azimutt', tables: [{name: 'users'}]}, 1)).toEqual({db: 'azimutt', tables: '...'})
            expect(limitDepth({db: 'azimutt', tables: [{name: 'users'}]}, 2)).toEqual({db: 'azimutt', tables: ['...']})
            expect(limitDepth({db: 'azimutt', tables: [{name: 'users'}]}, 3)).toEqual({db: 'azimutt', tables: [{name: 'users'}]})
        })
        test('long arrays', () => {
            expect(limitDepth([1, 2, 3, 4, 5, 6, 7], 1)).toEqual([1, 2, 3, '...'])
        })
        test('long strings', () => {
            expect(limitDepth('bonjour à tous, cette fonction rends les objects petits', 1)).toEqual('bonjour à tous, cette fonction...')
        })
    })
})
