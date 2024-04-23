import {describe, test} from "@jest/globals";
import {Connection, ConnectionOptions, createConnection, SnowflakeError, Statement} from "snowflake-sdk";
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
    // https://docs.snowflake.com/en/user-guide/organizations-connect#standard-account-urls
    // const url = 'https://<user>:<pass>@<account>.snowflakecomputing.com/<database>'
    const url = 'snowflake://<user>:<pass>@<account>.snowflakecomputing.com?db=<database>'

    // TODO 2: write a valid query for your database
    const query = `
        SELECT cc.CC_CALL_CENTER_SK, cc.CC_NAME, c.C_CUSTOMER_SK, c.C_EMAIL_ADDRESS, r.CR_REFUNDED_CASH
        FROM TPCDS_SF10TCL.CATALOG_RETURNS r
            JOIN TPCDS_SF10TCL.CALL_CENTER cc ON r.CR_CALL_CENTER_SK = cc.CC_CALL_CENTER_SK
            JOIN TPCDS_SF10TCL.CUSTOMER c ON r.CR_REFUNDED_CUSTOMER_SK = c.C_CUSTOMER_SK
        LIMIT 30;`
    const parameters: any[] = []

    // TODO 3: unskip this test first and run it (`npm run test -- src/connect.test.ts`)
    test.skip('Azimutt should connect', async () => {
        const parsedUrl = parseDatabaseUrl(url)
        const results = await connect(application, parsedUrl, execQuery(query, parameters), {logger, logQueries: true})
        console.log('results', results)
    }, 10000)

    // TODO 4: if previous test failed, unskip this one an find how https://www.npmjs.com/package/snowflake-sdk can connect to your database
    // tips: check lib version in package.json, ping us if you need help
    test.skip('NodeJS should connect', async () => {
        const options: ConnectionOptions = {
            application: 'azimutt',
            account: 'orgname-account_name',
            username: 'username',
            password: 'password',
            // accessUrl: url,
        }
        const connection: Connection = createConnection(options)
        try {
            await new Promise((resolve, reject) => connection.connect((err: SnowflakeError | undefined, conn: Connection) => {
                if (err) {
                    console.error('Unable to connect: ' + err.message)
                    reject(err)
                } else {
                    console.log('Successfully connected to Snowflake.')
                    resolve(conn)
                }
            }))
            await new Promise((resolve, reject) => connection.execute({
                sqlText: query,
                complete: (err: SnowflakeError | undefined, stmt: Statement, rows: any[] | undefined) => {
                    if (err) {
                        console.log('Unable to execute', err)
                        reject(err)
                    } else {
                        console.log('Executed statement', stmt)
                        console.log('Resulted rows', rows)
                        resolve(rows)
                    }
                }
            }))
        } finally {
            await new Promise((resolve, reject) => connection.destroy((err: SnowflakeError | undefined) => {
                if (err) {
                    console.error('Unable to disconnect: ' + err.message)
                    reject(err)
                } else {
                    console.log('Successfully disconnected from Snowflake.')
                    resolve(undefined)
                }
            }))
        }
    })
})
