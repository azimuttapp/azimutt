import {describe, expect, test} from "@jest/globals";
import {AzimuttSchema, DatabaseUrlParsed, parseDatabaseUrl} from "@azimutt/database-types";
import {application, logger} from "./constants";
import {execQuery} from "../src/common";
import {connect} from "../src/connect";
import {formatSchema, getSchema, MariadbSchema} from "../src/mariadb";

describe('mariadb', () => {
    // fake url, use a real one to test (see README for how-to)
    const url: DatabaseUrlParsed = parseDatabaseUrl('mariadb://user:pass@host.com:3306/db')
    test.skip('execQuery', async () => {
        const results = await connect(application, url, execQuery("SELECT * FROM airlines;", []))
        console.log('results', results)
        expect(results.rows.length).toEqual(1)
    })
    test.skip('getSchema', async () => {
        const schema = await connect(application, url, getSchema(undefined, 10, logger))
        console.log('schema', schema)
        expect(schema.tables.length).toEqual(6)
    })
    test('formatSchema', () => {
        const rawSchema: MariadbSchema = {tables: [], relations: [], types: []}
        const expectedSchema: AzimuttSchema = {tables: [], relations: [], types: []}
        expect(formatSchema(rawSchema, false)).toEqual(expectedSchema)
    })
})
