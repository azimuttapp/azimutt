import {describe, test} from "@jest/globals";
import * as oracledb from "oracledb";
import {parseDatabaseUrl} from "@azimutt/models";
import {connect} from "./connect";
import {execQuery} from "./query";
import {application, logger} from "./constants.test";

// Use this test to troubleshoot database connection errors.
// If you don't succeed with the first one (Azimutt `connect`), try with the second one (raw node lib) and once you found a way, tell us how to fix ;)
// Of course, you can contact us (issues or contact@azimutt.app) to do it together.
// More documentation available at: https://azimutt.notion.site/Database-connection-troubleshooting-c4c19ed28c7040ef9aaaeec96ce6ba8d
describe('connect', () => {
    // TODO 1: replace this with your own connection string, but don't commit it!
    const url = 'oracle:thin:system/oracle@localhost:1521'

    // TODO 2: write a valid query for your database
    const query = 'SELECT id, name FROM users FETCH FIRST 2 ROWS ONLY'
    const parameters: any[] = []

    // TODO 3: unskip this test first and run it (`npm run test -- src/connect.test.ts`)
    test.skip('Azimutt should connect', async () => {
        const parsedUrl = parseDatabaseUrl(url)
        const results = await connect(application, parsedUrl, execQuery(query, parameters), {logger, logQueries: true})
        console.log('results', results)
    })

    // TODO 4: if previous test failed, unskip this one an find how https://www.npmjs.com/package/oracledb can connect to your database
    // tips: check lib version in package.json, ping us if you need help
    test.skip('NodeJS should connect', async () => {
        let connection: oracledb.Connection | undefined
        try {
            const config: oracledb.ConnectionAttributes = {connectionString: `localhost:1521`, user: 'system', password: 'oracle'}
            connection = await oracledb.getConnection(config)
            console.log('connected!')
            const opts: oracledb.ExecuteOptions = {outFormat: oracledb.OUT_FORMAT_OBJECT}
            const results = await connection.execute(query, parameters, opts)
            console.log('results', results)
        } catch (err) {
            console.log('err', err)
        } finally {
            if (connection) {
                try {
                    await connection.close()
                } catch (err) {
                    console.error('Err on connection close', err)
                }
            }
        }
    })
})
