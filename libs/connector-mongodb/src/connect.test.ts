import {describe, test} from "@jest/globals";
import {MongoClient} from "mongodb";
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
    const url = 'mongodb+srv://user:password@cluster2.gu2a9mr.mongodb.net'

    // TODO 2: write a valid query for your database
    const query = 'sample_mflix/movies/find/{"runtime":{"$eq":1}}'

    // TODO 3: unskip this test first and run it (`npm run test -- src/connect.test.ts`)
    test.skip('Azimutt should connect', async () => {
        const parsedUrl = parseDatabaseUrl(url)
        const results = await connect(application, parsedUrl, execQuery(query, []), {logger, logQueries: true})
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
