import {describe, expect, test} from "@jest/globals";
import {AzimuttSchema, DatabaseUrlParsed, parseDatabaseUrl} from "@azimutt/database-types";
import {application, logger} from "./constants";
import {execQuery} from "../src/common";
import {connect} from "../src/connect";
import {formatSchema, getSchema, PostgresSchema} from "../src/postgres";

describe('postgres', () => {
    // local url, install db or replace it to test
    const url: DatabaseUrlParsed = parseDatabaseUrl('postgresql://postgres:postgres@localhost:5432/azimutt_dev')
    test.skip('execQuery', async () => {
        const results = await connect(application, url, execQuery('SELECT * FROM users WHERE email = $1 LIMIT 2;', ['admin@azimutt.app']))
        console.log('results', results)
        expect(results.rows.length).toEqual(1)
    })
    test.skip('getSchema', async () => {
        const schema = await connect(application, url, getSchema(undefined, 10, logger))
        console.log('schema', schema)
        expect(schema.tables.length).toEqual(13)
    })
    test('formatSchema', () => {
        const rawSchema: PostgresSchema = {tables: [], relations: [], types: []}
        const expectedSchema: AzimuttSchema = {tables: [], relations: [], types: []}
        expect(formatSchema(rawSchema, false)).toEqual(expectedSchema)
    })
})
