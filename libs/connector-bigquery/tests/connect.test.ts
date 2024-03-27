import {describe, test} from "@jest/globals";
import {BigQuery, BigQueryOptions} from "@google-cloud/bigquery";
// import {parseDatabaseUrl} from "@azimutt/database-types";
// import {connect} from "../src/connect";
// import {application, logger} from "./constants";
// import {execQuery} from "../src/common";

// Use this test to troubleshoot database connection errors.
// If you don't succeed with the first one (Azimutt `connect`), try with the second one (raw node lib) and once you found a way, tell us how to fix ;)
// Of course, you can contact us (issues or contact@azimutt.app) to do it together.
// More documentation available at: https://azimutt.notion.site/Database-connection-troubleshooting-c4c19ed28c7040ef9aaaeec96ce6ba8d
describe('connect', () => {
    // TODO 1: replace this with your own connection string, but don't commit it!
    const url = 'postgresql://postgres:postgres@localhost:5432/azimutt_dev'

    // TODO 2: write a valid query for your database
    const query = 'SELECT * FROM users LIMIT 2;'
    const parameters: any[] = []

    // TODO 3: unskip the this test and run it: `npm run test -- tests/connect.test.ts`
    /*test.skip('Azimutt should connect', async () => {
        const parsedUrl = parseDatabaseUrl(url)
        const results = await connect(application, parsedUrl, execQuery(query, parameters), {logger})
        console.log('results', results)
    })*/

    // TODO 4: if previous test failed, unskip this one an find how https://www.npmjs.com/package/@google-cloud/bigquery can connect to your database
    // tips: check lib version in package.json, ping us if you need help
    test.skip('NodeJS should connect', async () => {
        // Using [Application Default Credentials](https://cloud.google.com/docs/authentication/application-default-credentials)
        // Put your [service account key](https://console.cloud.google.com/iam-admin/serviceaccounts) in `local/key.json` or change the `GOOGLE_APPLICATION_CREDENTIALS` path
        // https://cloud.google.com/bigquery/docs/information-schema-intro
        process.env.GOOGLE_APPLICATION_CREDENTIALS = 'local/key.json'
        const client = new BigQuery()
        const id = await client.getProjectId()
        console.log(`project id`, id)
        const datasets = await client.getDatasets()
        console.log(`${datasets.length} datasets`, datasets)
        const datasetIds = datasets.flatMap((dl: any) => dl.map((d: any) => d.id))
        console.log('datasetIds', datasetIds)
        // const columns = await client.query("SELECT * FROM `bigquery-public-data.baseball.INFORMATION_SCHEMA.TABLES` LIMIT 10;")
        // const columns = await client.query("SELECT * FROM `azimutt-experiments.baseball.INFORMATION_SCHEMA.TABLES` LIMIT 10;")
        const columns = await client.query("SELECT * FROM `azimutt-experiments.baseball.SCHEMATA` LIMIT 10;")
        console.log(`columns`, columns)
    }, 15 * 1000)
})
