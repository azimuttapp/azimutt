import {describe, expect, test} from "@jest/globals";
import {AzimuttSchema} from "@azimutt/database-types";
import {logger, url} from "./constants";
import {formatSchema, getSchema, PostgresSchema} from "../src";

describe('schema', () => {
    test.skip('getSchema', async () => {
        const schema = await getSchema(url, undefined, 10, logger)
        expect(schema.tables.length).toEqual(12)
    })
    test('formatSchema', () => {
        const rawSchema: PostgresSchema = {tables: [], relations: [], types: []}
        const expectedSchema: AzimuttSchema = {tables: [], relations: [], types: []}
        expect(formatSchema(rawSchema, 0, false)).toEqual(expectedSchema)
    })
})
