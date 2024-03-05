import {describe, expect, test} from "@jest/globals";
import {isPolymorphicColumn} from "../src";

describe('connector', () => {
    describe('isPolymorphicColumn', () => {
        const columns = ['id', 'name', 'item_id', 'item_type', 'resource_type']
        test('columns with `type` suffix are polymorphic if they have a matching id column', () => {
            expect(isPolymorphicColumn('item_type', columns)).toBeTruthy()
        })
        test('columns with `type` suffix are not polymorphic without a matching id column', () => {
            expect(isPolymorphicColumn('resource_type', columns)).toBeFalsy()
        })
        test('columns without `type` suffix are not polymorphic', () => {
            expect(isPolymorphicColumn('name', columns)).toBeFalsy()
        })
    })
})
