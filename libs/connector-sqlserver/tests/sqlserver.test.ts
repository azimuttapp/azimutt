import {describe, expect, test} from "@jest/globals";
import {AzimuttSchema, DatabaseUrlParsed, parseDatabaseUrl} from "@azimutt/database-types";
import {application, logger} from "./constants";
import {execQuery} from "../src/common";
import {connect} from "../src/connect";
import {formatSchema, getSchema, SqlserverSchema} from "../src/sqlserver";

describe('sqlserver', () => {
    // fake url, use a real one to test (see README for how-to)
    const url: DatabaseUrlParsed = parseDatabaseUrl('Server=host.com,1433;Database=db;User Id=user;Password=pass')
    test.skip('execQuery', async () => {
        const results = await connect(application, url, execQuery("SELECT * FROM Departments WHERE DepartmentCode='DS';", []), {logQueries: true, logger})
        console.log('results', results)
        expect(results.rows.length).toEqual(1)
    })
    test('getSchema', async () => {
        const schemaName = undefined
        const pageSize = 1000
        const sampleSize = 10
        const schema = await connect(application, url, getSchema(schemaName, pageSize, sampleSize, false, logger), {logQueries: true, logger})
        console.log('schema', schema)
        expect(schema.tables.length).toEqual(32)
    }, 10 * 1000)
    test('formatSchema', () => {
        const rawSchema: SqlserverSchema = {tables: [], relations: [], types: []}
        const expectedSchema: AzimuttSchema = {tables: [], relations: [], types: []}
        expect(formatSchema(rawSchema, false)).toEqual(expectedSchema)
    })
})
