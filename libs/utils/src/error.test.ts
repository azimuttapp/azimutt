import {describe, expect, test} from "@jest/globals";
import {errorToString} from "./error";

describe('error', () => {
    test('errorToString', () => {
        expect(errorToString(new Error('My error'))).toEqual('My error')
        expect(errorToString('My error')).toEqual('My error')
        expect(errorToString({error: 'My error'})).toEqual('My error')
        expect(errorToString({message: 'My error'})).toEqual('My error')
        expect(errorToString({json: {message: 'My error'}})).toEqual('My error')
        expect(errorToString({other: 'My error'})).toEqual('{"other":"My error"}')
    })
})
