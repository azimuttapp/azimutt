import {describe, expect, test} from "@jest/globals";
import {Result} from "./result";

describe('result', () => {
    test('getOrThrow', () => {
        expect(Result.success(1).getOrThrow()).toEqual(1)
        expect(() => Result.failure('err').getOrThrow()).toThrow('err')
    })
    test('getOrNull', () => {
        expect(Result.success(1).getOrNull()).toEqual(1)
        expect(Result.failure('err').getOrNull()).toEqual(null)
    })
    test('errOrNull', () => {
        expect(Result.success(1).errOrNull()).toEqual(null)
        expect(Result.failure('err').errOrNull()).toEqual('err')
    })
    test('toJson', () => {
        expect(Result.success(1).toJson()).toEqual({success: 1})
        expect(Result.failure('err').toJson()).toEqual({failure: 'err'})
    })
    test('swap', () => {
        expect(Result.success(1).swap().toJson()).toEqual({failure: 1})
        expect(Result.failure('err').swap().toJson()).toEqual({success: 'err'})
    })
    test('map', () => {
        expect(Result.success(1).map(i => i + 1).toJson()).toEqual({success: 2})
        expect(Result.failure('err').map(i => i + 1).toJson()).toEqual({failure: 'err'})
    })
    test('mapError', () => {
        expect(Result.success(1).mapError(i => i + 1).toJson()).toEqual({success: 1})
        expect(Result.failure('err').mapError(i => i + '2').toJson()).toEqual({failure: 'err2'})
    })
    test('flatMap', () => {
        expect(Result.success(1).flatMap(i => Result.success(i + 1)).toJson()).toEqual({success: 2})
        expect(Result.success(1).flatMap(i => Result.failure('err')).toJson()).toEqual({failure: 'err'})
        expect(Result.failure('err').flatMap(i => Result.success(i + 1)).toJson()).toEqual({failure: 'err'})
        expect(Result.failure('err1').flatMap(i => Result.failure('err2')).toJson()).toEqual({failure: 'err1'})
    })
    test('fold', () => {
        expect(Result.success<number, string>(1).fold(i => i.toString(), e => e)).toEqual('1')
        expect(Result.failure<string, number>('err').fold(i => i.toString(), e => e)).toEqual('err')
    })
    test('toPromise', async () => {
        await expect(Result.success(1).toPromise()).resolves.toEqual(1)
        await expect(Result.failure('err').toPromise()).rejects.toEqual('err')
    })
})
