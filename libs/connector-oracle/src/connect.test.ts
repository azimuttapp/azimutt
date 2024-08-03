import {describe, test} from "@jest/globals";
import * as oracledb from "oracledb";
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
        const parsedUrl = parseDatabaseUrl('oracle:thin:system/oracle@localhost:1521/FREE')
        const query = 'SELECT * FROM users FETCH FIRST 2 ROWS ONLY;'
        const results = await connect(application, parsedUrl, execQuery(query, []), {logger, logQueries: true})
        console.log('results', results)
    })

    // TODO 2: if previous test failed, debug connecting using row https://www.npmjs.com/package/oracledb: replace url & query, then unskip this test and run it
    // tip: check lib version in ../package.json, ping us if you need help
    test.skip('NodeJS connect', async () => {
        let connection: oracledb.Connection | undefined
        try {
            const config: oracledb.ConnectionAttributes = {connectionString: `localhost:1521`, user: 'system', password: 'oracle'}
            const query = 'SELECT * FROM users FETCH FIRST 2 ROWS ONLY'
            connection = await oracledb.getConnection(config)
            console.log('connected!')
            const opts: oracledb.ExecuteOptions = {outFormat: oracledb.OUT_FORMAT_OBJECT}
            const results = await connection.execute(query, [], opts)
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
