import {describe, expect, test} from "@jest/globals";
import {DatabaseUrlParsed, parseDatabaseUrl} from "@azimutt/database-types";
import {application, logger} from "./constants";
import {getSchema} from "../src";

// to have at least one test in every module ^^
describe('couchbase', () => {
    // fake url, use a real one to test
    const url: DatabaseUrlParsed = parseDatabaseUrl('couchbases://cb.bdej1379mrnpd5me.cloud.couchbase.com')
    test.skip('getSchema', async () => {
        const schema = await getSchema(application, url, undefined, 10, logger)
        expect(schema.collections.length).toEqual(12)
    })
})
