import {describe, test} from "@jest/globals";
import * as couchbase from "couchbase";
import {Cluster, QueryResult} from "couchbase";
import {parseDatabaseUrl} from "@azimutt/database-types";
import {application} from "./constants";
import {execQuery} from "../src";
import {connect} from "../src/connect";

// use this test to troubleshoot connection errors
// if you don't succeed with the first one (Azimutt code), try with the second one (node lib) and tell us how to fix ;)
// More documentation available at: https://azimutt.notion.site/Database-connection-troubleshooting-c4c19ed28c7040ef9aaaeec96ce6ba8d
describe('connect', () => {
    // TODO 1: replace this with your own connection string, but don't commit it!
    const url = 'couchbases://my_user:my_password@cb.bdej1379mrnpd5me.cloud.couchbase.com'

    // TODO 2: write a valid query for your database
    const query = 'SELECT name FROM `travel-sample`.inventory.hotel LIMIT 3;'
    const parameters: any[] = []

    // TODO 3: unskip the this test first and run it: `npm run test -- tests/connect.test.ts`
    test.skip('Azimutt should connect', async () => {
        const parsedUrl = parseDatabaseUrl(url)
        const results = await connect(application, parsedUrl, execQuery(query, parameters))
        console.log('results', results)
    })

    // TODO 4: if previous test failed, unskip this one an find how https://www.npmjs.com/package/couchbase can connect to your database
    // tips: check lib version in package.json, ping us if you need help
    test.skip('NodeJS should connect', async () => {
        const cluster: Cluster = await couchbase.connect(url, {username: 'user', password: 'pass'})
        try {
            const results: QueryResult<any> = await cluster.query(query, {parameters})
            console.log('results', results)
        } finally {
            await cluster.close()
        }
    })
})
