import {describe, test} from "@jest/globals";
import {Client} from "pg";
import {parseDatabaseUrl} from "@azimutt/database-types";
import {connect} from "../src/connect";
import {application} from "./constants";
import {execQuery} from "../src/common";

// use this test to troubleshoot connection errors
// if you don't succeed with the first one (Azimutt code), try with the second one (node lib) and tell us how to fix ;)
describe('connect', () => {
    const url = 'postgresql://postgres:postgres@localhost:5432/azimutt_dev'
    const parsedUrl = parseDatabaseUrl(url)
    const query = 'SELECT * FROM users LIMIT 2;'

    test.skip('should connect to postgres', async () => {
        const results = await connect(application, parsedUrl, execQuery(query, []))
        console.log('results', results)
    })

    test.skip('should connect to postgres', async () => {
        const client = new Client({
            application_name: application,
            connectionString: url
        })
        await client.connect()
        const results = await client.query(query)
        console.log('results', results)
        await client.end()
    })
})
