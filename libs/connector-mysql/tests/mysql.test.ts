import {describe, expect, test} from "@jest/globals";
import {AzimuttSchema, DatabaseUrlParsed, parseDatabaseUrl} from "@azimutt/database-types";
import {application, logger} from "./constants";
import {execQuery, formatSchema, getSchema, MysqlSchema} from "../src";

describe('postgres', () => {
    // fake url, use a real one to test (see README for how-to)
    const url: DatabaseUrlParsed = parseDatabaseUrl('jdbc:mysql://user:pass@host.com:3306/db')
    test.skip('execQuery', async () => {
        const results = await execQuery(application, url, "SELECT name, slug FROM users WHERE slug = ?;", ['ghost'])
        console.log('results', results)
        expect(results.rows.length).toEqual(1)
    })
    test.skip('getSchema', async () => {
        const schema = await getSchema(application, url, undefined, 10, logger)
        console.log('schema', schema)
        expect(schema.tables.length).toEqual(34)
    })
    test('formatSchema', () => {
        const rawSchema: MysqlSchema = {tables: [], relations: [], types: []}
        const expectedSchema: AzimuttSchema = {tables: [], relations: [], types: []}
        expect(formatSchema(rawSchema, false)).toEqual(expectedSchema)
    })
})
