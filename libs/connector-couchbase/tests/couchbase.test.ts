import {describe, expect, test} from "@jest/globals";
import {DatabaseUrlParsed, parseDatabaseUrl} from "@azimutt/database-types";
import {application, logger} from "./constants";
import {execQuery, getSchema} from "../src";

// to have at least one test in every module ^^
describe('couchbase', () => {
    // fake url, use a real one to test (see README for how-to)
    const url: DatabaseUrlParsed = parseDatabaseUrl('couchbases://my_user:my_password@cb.bdej1379mrnpd5me.cloud.couchbase.com')
    test.skip('execQuery', async () => {
        const result = await execQuery(application, url, 'SELECT name FROM `travel-sample`.inventory.hotel LIMIT $1;', [3])
        expect(result.rows.length).toEqual(3)
    })
    test.skip('getSchema', async () => {
        const schema = await getSchema(application, url, undefined, 10, logger)
        expect(schema.collections.length).toEqual(16)
    })
})
