import {describe, test} from "@jest/globals";
import {Connection, ConnectionOptions, createConnection, SnowflakeError, Statement} from "snowflake-sdk";
import {parseDatabaseUrl, DatabaseUrlParsed} from "@azimutt/database-types";
import {connect} from "../src/connect";
import {application} from "./constants";
import {execQuery} from "../src/common";

// use this test to troubleshoot connection errors
// if you don't succeed with the first one (Azimutt code), try with the second one (node lib) and tell us how to fix ;)
// More documentation available at: https://azimutt.notion.site/Database-connection-troubleshooting-c4c19ed28c7040ef9aaaeec96ce6ba8d
describe('connect', () => {
    // TODO 1: replace this with your own connection string, but don't commit it!
    // https://docs.snowflake.com/en/user-guide/organizations-connect#standard-account-urls
    // const url = 'https://<user>:<pass>@<account>.snowflakecomputing.com/<database>'
    const url = 'snowflake://<user>:<pass>@<account>.snowflakecomputing.com?db=<database>'

    // TODO 2: write a valid query for your database
    const query = 'SELECT * FROM TPCDS_SF100TCL.WEB_SITE LIMIT 10;'
    // const query = 'SHOW TABLES;'
    const parameters: any[] = []

    // TODO 3: unskip the this test first and run it: `npm run test -- tests/connect.test.ts`
    test('Azimutt should connect', async () => {
        const parsedUrl = parseDatabaseUrl(url)
        const results = await connect(application, parsedUrl, execQuery(query, parameters))
        console.log('results', results)
    })

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
