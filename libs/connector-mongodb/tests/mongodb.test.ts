import {describe, expect, test} from "@jest/globals";
import {DatabaseUrlParsed, parseDatabaseUrl} from "@azimutt/database-types";
import {application, logger} from "./constants";
import {execQuery, getSchema} from "../src";

// to have at least one test in every module ^^
describe('mongodb', () => {
    // fake url, use a real one to test (see README for how-to)
    const url: DatabaseUrlParsed = parseDatabaseUrl('mongodb+srv://user:password@cluster2.gu2a9mr.mongodb.net')
    test.skip('execQuery', async () => {
        const results = await execQuery(application, url, 'sample_mflix/movies/find/{"runtime":{"$eq":1}}')
        console.log('results', results)
        expect(results.rows.length).toEqual(6)
    })
    test.skip('getSchema', async () => {
        const schema = await getSchema(application, url, undefined, 10, logger)
        expect(schema.collections.length).toEqual(22)
    })
})
