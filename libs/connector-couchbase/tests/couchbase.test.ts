import {describe, expect, test} from "@jest/globals";
import {ConnectorSchemaOpts, DatabaseUrlParsed, parseDatabaseUrl} from "@azimutt/models";
import {connect} from "../src/connect";
import {execQuery} from "../src/query";
import {getSchema} from "../src/couchbase";
import {application, logger} from "./constants";

// to have at least one test in every module ^^
describe('couchbase', () => {
    // fake url, use a real one to test (see README for how-to)
    const url: DatabaseUrlParsed = parseDatabaseUrl('couchbases://my_user:my_password@cb.bdej1379mrnpd5me.cloud.couchbase.com')
    const opts: ConnectorSchemaOpts = {logger, logQueries: false, inferJsonAttributes: true, inferPolymorphicRelations: true}

    test.skip('execQuery', async () => {
        const results = await connect(application, url, execQuery('SELECT name FROM `travel-sample`.inventory.hotel LIMIT $1;', [3]), opts)
        console.log('results', results)
        expect(results.rows.length).toEqual(3)
    })
    test.skip('getSchema', async () => {
        const schema = await connect(application, url, getSchema(opts), opts)
        console.log('schema', schema)
        expect(schema.entities?.length).toEqual(16)
    }, 60000)
    test.skip('explore indexes', async () => {
        // await connect(url, async cluster => {
        //     const bucket = cluster.bucket('travel-sample')
        //     const scope = bucket.scope('inventory')
        //     const collection = scope.collection('hotel')
        //     const result = await scope.query('SELECT Meta() as _meta, hotel.* FROM hotel LIMIT 3')
        //     console.log(result.rows)
        // })

        const indexes = await connect(application, url, execQuery('SELECT * FROM system:indexes;', []), opts)
        console.log('indexes', indexes.rows.map((r: any) => r.indexes))

        const requests = await connect(application, url, execQuery('SELECT * FROM system:completed_requests;', []), opts)
        console.log('requests', requests.rows) // empty :/
    })
})
