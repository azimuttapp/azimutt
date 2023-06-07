import {describe, expect, test} from "@jest/globals";
import {DatabaseUrlParsed, parseDatabaseUrl} from "@azimutt/database-types";
import {application} from "./constants";
import {execQuery} from "../src/query";

describe('sqlserver', () => {
    // fake url, use a real one to test (see README for how-to)
    const url: DatabaseUrlParsed = parseDatabaseUrl('Server=host.com,1433;Database=db;User Id=user;Password=pass')
    test.skip('execQuery', async () => {
        const results = await execQuery(application, url, "SELECT * FROM Departments WHERE DepartmentCode='DS';", [])
        console.log('results', results)
        expect(results.rows.length).toEqual(1)
    })
    /* test.skip('getSchema', async () => {
        const schema = await getSchema(application, url, undefined, 10, logger)
        console.log('schema', schema)
        expect(schema.tables.length).toEqual(34)
    })
    test('formatSchema', () => {
        const rawSchema: SqlserverSchema = {tables: [], relations: [], types: []}
        const expectedSchema: AzimuttSchema = {tables: [], relations: [], types: []}
        expect(formatSchema(rawSchema, false)).toEqual(expectedSchema)
    }) */
})
