import {describe, expect, test} from "@jest/globals";
import {DatabaseUrlParsed, parseDatabaseUrl} from "@azimutt/database-model";
import {application, logger} from "./constants";
import {CouchbaseSchemaOpts, execQuery, getSchema} from "../src";
import {connect} from "../src/connect";

// to have at least one test in every module ^^
describe('couchbase', () => {
    // fake url, use a real one to test (see README for how-to)
    const url: DatabaseUrlParsed = parseDatabaseUrl('couchbases://my_user:my_password@cb.bdej1379mrnpd5me.cloud.couchbase.com')
    test.skip('execQuery', async () => {
        const results = await connect(application, url, execQuery('SELECT name FROM `travel-sample`.inventory.hotel LIMIT $1;', [3]))
        console.log('results', results)
        expect(results.rows.length).toEqual(3)
    })
    test.skip('getSchema', async () => {
        const schemaOpts: CouchbaseSchemaOpts = {logger, bucket: undefined, mixedCollection: undefined, sampleSize: 10, ignoreErrors: false}
        const schema = await connect(application, url, getSchema(schemaOpts))
        expect(schema.collections.length).toEqual(16)
    }, 60000)
    test.skip('explore indexes', async () => {
        // await connect(url, async cluster => {
        //     const bucket = cluster.bucket('travel-sample')
        //     const scope = bucket.scope('inventory')
        //     const collection = scope.collection('hotel')
        //     const result = await scope.query('SELECT Meta() as _meta, hotel.* FROM hotel LIMIT 3')
        //     console.log(result.rows)
        // })

        const indexes = await connect(application, url, execQuery('SELECT * FROM system:indexes;', []))
        console.log('indexes', indexes.rows.map(r => r.indexes))

        const requests = await connect(application, url, execQuery('SELECT * FROM system:completed_requests;', []))
        console.log('requests', requests.rows) // empty :/
    })
})
