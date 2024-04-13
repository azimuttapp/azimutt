import {describe, expect, test} from "@jest/globals";
import {ConnectorSchemaOpts, DatabaseUrlParsed, parseDatabaseUrl} from "@azimutt/models";
import {application, logger} from "./constants";
import {connect} from "../src/connect";
import {execQuery} from "../src/query";
import {getSchema} from "../src/sqlserver";

describe('sqlserver', () => {
    // fake url, use a real one to test (see README for how-to)
    const url: DatabaseUrlParsed = parseDatabaseUrl('Server=host.com,1433;Database=db;User Id=user;Password=pass')
    const opts: ConnectorSchemaOpts = {logger, logQueries: true, inferJsonAttributes: true, inferPolymorphicRelations: true}

    test.skip('execQuery', async () => {
        const results = await connect(application, url, execQuery("SELECT * FROM Departments WHERE DepartmentCode='DS';", []), opts)
        console.log('results', results)
        expect(results.rows.length).toEqual(1)
    })
    test.skip('getSchema', async () => {
        const schema = await connect(application, url, getSchema(opts), opts)
        console.log('schema', schema)
        expect(schema.entities?.length).toEqual(32)
    })
})
