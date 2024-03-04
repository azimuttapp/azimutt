import {describe, expect, test} from "@jest/globals";
import {deeplyRemoveFields, filterValues, mapValues} from "../src";
import {mapValuesAsync} from "../out";

describe('object', () => {
    test('mapValues', () => {
        expect(mapValues({a: 'luc', b: 'jean'}, v => v.length)).toEqual({a: 3, b: 4})
    })
    test('mapValuesAsync', async () => {
        expect(await mapValuesAsync({a: 'luc', b: 'jean'}, async v => v.length)).toEqual({a: 3, b: 4})
    })
    test('filterValues', () => {
        expect(filterValues({a: 1, b: 2, c: 3, d: 4}, (v: number) => v % 2 === 0)).toEqual({b: 2, d: 4})
    })
    test('deeplyRemoveFields', () => {
        expect(deeplyRemoveFields({
            id: 1,
            name: 'test',
            children: [
                {id: 2, name: 'child'}
            ]
        }, ['id'])).toEqual({name: 'test', children: [{name: 'child'}]})
    })
})
