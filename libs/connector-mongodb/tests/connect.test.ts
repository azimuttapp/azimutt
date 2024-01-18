import {describe, test} from "@jest/globals";
import {MongoClient} from "mongodb";
import {parseDatabaseUrl} from "@azimutt/database-types";
import {execQuery} from "../src";
import {application} from "./constants";

// use this test to troubleshoot connection errors
// if you don't succeed with the first one (Azimutt code), try with the second one (node lib) and tell us how to fix ;)
// More documentation available at: https://azimutt.notion.site/Database-connection-troubleshooting-c4c19ed28c7040ef9aaaeec96ce6ba8d
describe('connect', () => {
    // TODO 1: replace this with your own connection string, but don't commit it!
    const url = 'mongodb+srv://user:password@cluster2.gu2a9mr.mongodb.net'

    // TODO 2: write a valid query for your database
    const query = 'sample_mflix/movies/find/{"runtime":{"$eq":1}}'

    // TODO 3: unskip the this test first and run it: `npm run test -- tests/connect.test.ts`
    test.skip('Azimutt should connect', async () => {
        const parsedUrl = parseDatabaseUrl(url)
        const results = await execQuery(application, parsedUrl, query)
        console.log('results', results)
    })

    // TODO 4: if previous test failed, unskip this one an find how https://www.npmjs.com/package/mongodb can connect to your database
    // tips: check lib version in package.json, ping us if you need help
    test.skip('NodeJS should connect', async () => {
        const client: MongoClient = new MongoClient(url)
        try {
            await client.connect()
            const coll = client.db('sample_mflix').collection('movies')
            const results = await coll.find({"$eq": 1}).limit(10).toArray()
            console.log('results', results)
        } finally {
            await client.close()
        }
    })
})
