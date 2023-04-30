import {describe, expect, test} from "@jest/globals";
import {DatabaseUrlParsed, parseDatabaseUrl} from "@azimutt/database-types";
import {application, logger} from "./constants";
import {getSchema} from "../src";

// to have at least one test in every module ^^
describe('mongodb', () => {
    // fake url, use a real one to test
    const url: DatabaseUrlParsed = parseDatabaseUrl('mongodb+srv://user:password@cluster2.gu2a9mr.mongodb.net')
    test.skip('getSchema', async () => {
        const schema = await getSchema(application, url, undefined, 10, logger)
        expect(schema.collections.length).toEqual(12)
    })
})
