import {describe, test} from "@jest/globals";
import * as mssql from "mssql";
import {ConnectionPool, IResult} from "mssql";
import {parseDatabaseUrl} from "@azimutt/database-types";
import {connect} from "../src/connect";
import {application, opts} from "./constants";
import {execQuery} from "../src/common";

// use this test to troubleshoot connection errors
// if you don't succeed with the first one (Azimutt code), try with the second one (node lib) and tell us how to fix ;)
// More documentation available at: https://azimutt.notion.site/Database-connection-troubleshooting-c4c19ed28c7040ef9aaaeec96ce6ba8d
describe('connect', () => {
    // TODO 1: replace with your own connection string, but don't commit it!
    const url = 'Server=host.com,1433;Database=db;User Id=user;Password=pass'

    // TODO 2: write a valid query for your database
    const query = 'SELECT TOP 2 * FROM ErrorLog;'
    const parameters: any[] = []

    // TODO 3: unskip this test and run it (`npm test -- -t 'Azimutt should connect'`)
    test.skip('Azimutt should connect', async () => {
        const parsedUrl = parseDatabaseUrl(url)
        const results = await connect(application, parsedUrl, execQuery(query, parameters), opts)
        console.log('results', results)
    })

    // TODO 4: if previous test failed, unskip this one and find how https://www.npmjs.com/package/mssql can connect to your database
    // tips: check lib version in package.json, ping us if you need help
    // run this test alone: `npm test -- -t 'NodeJS should connect'`
    test.skip('NodeJS should connect', async () => {
        const connection: ConnectionPool = await mssql.connect({
            server: 'host.com',
            port: 1433,
            user: 'user',
            password: 'pass',
            database: 'db'
        })
        try {
            const results: IResult<any> = await connection.query(query)
            console.log('results', results)
        } finally {
            await connection.close()
        }
    })
})
