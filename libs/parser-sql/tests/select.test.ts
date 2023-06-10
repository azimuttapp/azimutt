import {describe, expect, test} from "@jest/globals";
import {hello} from "../src";

describe('select', () => {
    test('hello', () => {
        expect(hello()).toEqual('world')
    })
})
