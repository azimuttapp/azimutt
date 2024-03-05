import {describe, expect, test} from "@jest/globals";
import {AzimuttSchema, DatabaseUrlParsed, parseDatabaseUrl} from "@azimutt/database-types";
import {application, logger, opts} from "./constants";
import {execQuery} from "../src/common";
import {connect} from "../src/connect";
import {formatSchema, getSchema, MysqlSchema, MysqlSchemaOpts} from "../src/mysql";

describe('mysql', () => {
    // fake url, use a real one to test (see README for how-to)
    const url: DatabaseUrlParsed = parseDatabaseUrl('mysql://user:pass@host.com:3306/db')
    test.skip('execQuery', async () => {
        const results = await connect(application, url, execQuery("SELECT name, slug FROM users WHERE slug = ?;", ['ghost']), opts)
        console.log('results', results)
        expect(results.rows.length).toEqual(1)
    })
    test.skip('getSchema', async () => {
        const schemaOpts: MysqlSchemaOpts = {logger, schema: undefined, sampleSize: 10, inferRelations: true, ignoreErrors: false}
        const schema = await connect(application, url, getSchema(schemaOpts), opts)
        console.log('schema', schema)
        expect(schema.tables.length).toEqual(34)
    })
    test('formatSchema', () => {
        const rawSchema: MysqlSchema = {tables: [], relations: [], types: []}
        const expectedSchema: AzimuttSchema = {tables: [], relations: [], types: []}
        expect(formatSchema(rawSchema)).toEqual(expectedSchema)
    })
})
