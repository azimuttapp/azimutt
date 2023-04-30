import {describe, expect, test} from "@jest/globals";
import {DatabaseUrlParsed, parseDatabaseUrl} from "@azimutt/database-types";
import {application} from "./constants";
import {execQuery} from "../src";

describe('query', () => {
    // local url, install db or replace it to test
    const url: DatabaseUrlParsed = parseDatabaseUrl('postgresql://postgres:postgres@localhost:5432/azimutt_dev')
    test.skip('execQuery', async () => {
        const result = await execQuery(application, url, 'SELECT * FROM users LIMIT 2;', [])
        expect(result.rows.length).toEqual(2)
    })
})
