import {describe, expect, test} from "@jest/globals";
import {ConnectorDefaultOpts, DatabaseUrlParsed, parseDatabaseUrl} from "@azimutt/database-model";
import {application, logger} from "./constants";
import {execQuery} from "../src/query";
import {connect} from "../src/connect";

describe('query', () => {
    // fake url, use a real one to test (see README for how-to)
    const url: DatabaseUrlParsed = parseDatabaseUrl('Server=host.com,1433;Database=db;User Id=user;Password=pass')
    test.skip('execQuery', async () => {
        const opts: ConnectorDefaultOpts = {logger, logQueries: true}
        const results = await connect(application, url, execQuery("SELECT * FROM Departments WHERE DepartmentCode='DS';", []), opts)
        console.log('results', results)
        expect(results.rows.length).toEqual(1)
    })
})
