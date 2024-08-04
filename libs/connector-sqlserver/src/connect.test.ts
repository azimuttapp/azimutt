import {describe, test} from "@jest/globals";
import * as mssql from "mssql";
import {parseDatabaseUrl} from "@azimutt/models";
import {connect} from "./connect";
import {execQuery} from "./query";
import {application, logger} from "./constants.test";

// Use this test to troubleshoot database connection errors.
// If you don't succeed with the first one (Azimutt connect), try with the second one (raw lib) and once you found a way, tell us which config worked ;)
// Of course, you can contact us (contact@azimutt.app or https://github.com/azimuttapp/azimutt/issues) to do it together.
// More documentation available at: https://azimutt.notion.site/Database-connection-troubleshooting-c4c19ed28c7040ef9aaaeec96ce6ba8d
describe('connect', () => {
    // TODO 1: replace url & query with yours then unskip this test and run it using `npm run test -- src/connect.test.ts`
    test.skip('Azimutt connect', async () => {
        const parsedUrl = parseDatabaseUrl('sqlserver://sa:azimutt_42@localhost:1433/master')
        const query = 'SELECT TOP 2 * FROM users;'
        const results = await connect(application, parsedUrl, execQuery(query, []), {logger, logQueries: true})
        console.log('results', results)
    })

    // TODO 2: if previous test failed, debug connecting using row https://www.npmjs.com/package/mssql: replace url & query, then unskip this test and run it
    // tip: check lib version in ../package.json, ping us if you need help
    test.skip('NodeJS connect', async () => {
        const config: mssql.config = {
            server: 'localhost',
            port: 1433,
            user: 'sa',
            password: 'azimutt_42',
            database: 'master',
            options: {trustServerCertificate: true}
        }
        const query = 'SELECT TOP 2 * FROM users;'
        const connection: mssql.ConnectionPool = await mssql.connect(config)
        try {
            const results: mssql.IResult<any> = await connection.query(query)
            console.log('results', results)
        } finally {
            await connection.close()
        }
    })
})
