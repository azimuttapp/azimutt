import {describe, test} from "@jest/globals";
import * as mysql from "mysql2/promise";
import {Connection, RowDataPacket, FieldPacket} from "mysql2/promise";
import {parseDatabaseUrl} from "@azimutt/database-types";
import {connect} from "../src/connect";
import {application, opts} from "./constants";
import {execQuery} from "../src/common";

// use this test to troubleshoot connection errors
// if you don't succeed with the first one (Azimutt code), try with the second one (node lib) and tell us how to fix ;)
// More documentation available at: https://azimutt.notion.site/Database-connection-troubleshooting-c4c19ed28c7040ef9aaaeec96ce6ba8d
describe('connect', () => {
    // TODO 1: replace this with your own connection string, but don't commit it!
    const url = 'mysql://user:pass@host.com:3306/db'

    // TODO 2: write a valid query for your database
    const query = 'SELECT * FROM users LIMIT 2;'
    const parameters: any[] = []

    // TODO 3: unskip the this test first and run it: `npm run test -- tests/connect.test.ts`
    test.skip('Azimutt should connect', async () => {
        const parsedUrl = parseDatabaseUrl(url)
        const results = await connect(application, parsedUrl, execQuery(query, parameters), opts)
        console.log('results', results)
    })

    // TODO 4: if previous test failed, unskip this one an find how https://www.npmjs.com/package/mysql2 can connect to your database
    // tips: check lib version in package.json, ping us if you need help
    test.skip('NodeJS should connect', async () => {
        const connection: Connection = await mysql.createConnection({
            host: 'host.com',
            port: 3306,
            user: 'user',
            password: 'pass',
            database: 'db',
            insecureAuth: true
        })
        try {
            const results: [RowDataPacket[], FieldPacket[]] = await connection.query<RowDataPacket[]>({sql: query, values: parameters})
            console.log('results', results)
        } finally {
            await connection.end()
        }
    })
})
