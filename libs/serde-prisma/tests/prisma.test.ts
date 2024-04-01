import {describe, expect, test} from "@jest/globals";
import {ParserResult} from "@azimutt/database-model";
import {generate, parse} from "../src/prisma";

describe('prisma', () => {
    test('basic schema',  () => {
        expect(parse('')).toEqual(ParserResult.failure([{name: 'Not implemented', message: 'Not implemented'}]))
        expect(generate({})).toEqual('Not implemented')
    })
})
