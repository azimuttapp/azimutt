import {queryParams, uriComponentEncoded} from "./url";

describe('url', () => {
    test('queryParams', () => {
        expect(queryParams('')).toEqual({})
        expect(queryParams('?key=value')).toEqual({key: 'value'})
        expect(queryParams('?key=value&k=v')).toEqual({key: 'value', k: 'v'})
        expect(queryParams('?key=value&k=v&test=dGVzdA==')).toEqual({key: 'value', k: 'v', test: 'dGVzdA=='})
    })
    test('uriComponentEncoded', () => {
        expect(uriComponentEncoded('azimutt')).toBeFalsy()
        expect(uriComponentEncoded('Hi%20Azimutt!')).toBeTruthy()
    })
})
