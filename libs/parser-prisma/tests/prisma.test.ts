import {describe, expect, test} from "@jest/globals";
import * as fs from "fs";

describe('prisma', () => {
    test('test', () => {
        const schema1 = fs.readFileSync('tests/resources/schema1.prisma', {encoding: 'utf8', flag: 'r'})
        console.log('schema1', schema1)
        expect(1 + 1).toEqual(2)
    })
})
