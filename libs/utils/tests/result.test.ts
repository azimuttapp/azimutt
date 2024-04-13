import {describe, expect, test} from "@jest/globals";
import {Result} from "../src";

describe('result', () => {
    test('getOrThrow', () => {
        expect(Result.success(1).getOrThrow()).toEqual(1)
        expect(() => Result.failure('err').getOrThrow()).toThrow('err')
    })
    test('getOrNull', () => {
        expect(Result.success(1).getOrNull()).toEqual(1)
        expect(Result.failure('err').getOrNull()).toEqual(null)
    })
    test('swap', () => {
        expect(Result.success(1).swap().getOrNull()).toEqual(null)
        expect(Result.failure('err').swap().getOrNull()).toEqual('err')
    })
    test('map', () => {
        expect(Result.success(1).map(i => i + 1).getOrNull()).toEqual(2)
        expect(Result.failure('err').map(i => i + 1).getOrNull()).toEqual(null)
    })
    test('flatMap', () => {
        expect(Result.success(1).flatMap(i => Result.success(i + 1)).getOrNull()).toEqual(2)
        expect(Result.success(1).flatMap(i => Result.failure('err')).getOrNull()).toEqual(null)
        expect(Result.failure('err').flatMap(i => Result.success(i + 1)).getOrNull()).toEqual(null)
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
