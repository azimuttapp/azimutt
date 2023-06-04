import {describe, test} from "@jest/globals";
import {DatabaseUrlParsed, parseDatabaseUrl} from "@azimutt/database-types";
import {application} from "./constants";
import {execQuery} from "../src/query";

describe('postgres', () => {
    // fake url, use a real one to test (see README for how-to)
    const url: DatabaseUrlParsed = parseDatabaseUrl('jdbc:mysql://user:pass@host.com:3306/db')
    test.skip('execQuery', async () => {
        const results = await execQuery(application, url, "SELECT name, slug FROM users WHERE slug = ?;", ['ghost'])
        console.log('results', results)
    })
})
