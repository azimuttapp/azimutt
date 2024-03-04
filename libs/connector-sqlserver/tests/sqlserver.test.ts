import {describe, expect, test} from "@jest/globals";
import {AzimuttSchema, DatabaseUrlParsed, parseDatabaseUrl} from "@azimutt/database-types";
import {application, logger, opts} from "./constants";
import {execQuery} from "../src/common";
import {connect} from "../src/connect";
import {formatSchema, getSchema, SqlserverSchema, SqlserverSchemaOpts} from "../src/sqlserver";

describe('sqlserver', () => {
    // fake url, use a real one to test (see README for how-to)
    const url: DatabaseUrlParsed = parseDatabaseUrl('Server=host.com,1433;Database=db;User Id=user;Password=pass')
    test.skip('execQuery', async () => {
        const results = await connect(application, url, execQuery("SELECT * FROM Departments WHERE DepartmentCode='DS';", []), opts)
        console.log('results', results)
        expect(results.rows.length).toEqual(1)
    })
    test.skip('getSchema', async () => {
        const schemaOpts: SqlserverSchemaOpts = {logger, schema: undefined, sampleSize: 10, inferRelations: true, ignoreErrors: false}
        const schema = await connect(application, url, getSchema(schemaOpts), opts)
        console.log('schema', schema)
        expect(schema.tables.length).toEqual(32)
    })
    test('formatSchema', () => {
        const rawSchema: SqlserverSchema = {tables: [], relations: [], types: []}
        const expectedSchema: AzimuttSchema = {tables: [], relations: [], types: []}
        expect(formatSchema(rawSchema)).toEqual(expectedSchema)
    })
})
