import {describe, expect, test} from "@jest/globals";
import {DatabaseUrlParsed, parseDatabaseUrl} from "@azimutt/database-types";
import {application, logger} from "./constants";
import {execQuery, getSchema} from "../src";

// to have at least one test in every module ^^
describe('couchbase', () => {
    // fake url, use a real one to test (see README for how-to)
    const url: DatabaseUrlParsed = parseDatabaseUrl('couchbases://my_user:my_password@cb.bdej1379mrnpd5me.cloud.couchbase.com')
    test.skip('execQuery', async () => {
        const results = await execQuery(application, url, 'SELECT name FROM `travel-sample`.inventory.hotel LIMIT $1;', [3])
        console.log('results', results)
        expect(results.rows.length).toEqual(3)
    })
    test.skip('getSchema', async () => {
        const schema = await getSchema(application, url, undefined, 10, logger)
        expect(schema.collections.length).toEqual(16)
    })
    test.skip('explore indexes', async () => {
        // await connect(url, async cluster => {
        //     const bucket = cluster.bucket('travel-sample')
        //     const scope = bucket.scope('inventory')
        //     const collection = scope.collection('hotel')
        //     const result = await scope.query('SELECT Meta() as _meta, hotel.* FROM hotel LIMIT 3')
        //     console.log(result.rows)
        // })

        const indexes = await execQuery(application, url, 'SELECT * FROM system:indexes;', [])
        console.log('indexes', indexes.rows.map(r => r.indexes))

        const requests = await execQuery(application, url, 'SELECT * FROM system:completed_requests;', [])
        console.log('requests', requests.rows) // empty :/
    })
})
