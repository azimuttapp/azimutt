import {describe, test} from "@jest/globals";
import {BigQuery} from "@google-cloud/bigquery";
import {SimpleQueryRowsResponse} from "@google-cloud/bigquery/build/src/bigquery";
import {parseDatabaseUrl} from "@azimutt/database-types";
import {connect} from "../src/connect";
import {execQuery} from "../src/query";
import {application, logger} from "./constants";

// Use this test to troubleshoot database connection errors.
// If you don't succeed with the first one (Azimutt `connect`), try with the second one (raw node lib) and once you found a way, tell us how to fix ;)
// Of course, you can contact us (issues or contact@azimutt.app) to do it together.
// More documentation available at: https://azimutt.notion.site/Database-connection-troubleshooting-c4c19ed28c7040ef9aaaeec96ce6ba8d
describe('connect', () => {
    // TODO 1: replace this with your own connection string, but don't commit it!
    const url = 'bigquery://bigquery.googleapis.com/azimutt-experiments?key=local/key.json'

    // TODO 2: write a valid query for your database
    const query = 'SELECT * FROM azimutt_connector_trial.azimutt_biggest_users WHERE string_field_0 = ? LIMIT 10;'
    const params: any[] = ['HumanTalks Paris orga']

    // TODO 3: unskip the this test and run it: `npm run test -- tests/connect.test.ts`
    test.skip('Azimutt should connect', async () => {
        const parsedUrl = parseDatabaseUrl(url)
        const results = await connect(application, parsedUrl, execQuery(query, params), {logger})
        console.log('results', results)
    })

    // TODO 4: if previous test failed, unskip this one an find how https://www.npmjs.com/package/@google-cloud/bigquery can connect to your database
    // tips: check lib version in package.json, ping us if you need help
    test.skip('NodeJS should connect', async () => {
        const client = new BigQuery({
            projectId: 'azimutt-experiments',
            keyFilename: 'local/key.json'
        })
        const res: SimpleQueryRowsResponse = await client.query({query, params})
        console.log('res', res)
    })
})
