import {describe, expect, test} from "@jest/globals";
import {DatabaseUrlParsed, parseDatabaseUrl} from "@azimutt/database-types";
import {application} from "./constants";
import {getColumnStats, getTableStats} from "../src";

describe('stats', () => {
    // fake url, use a real one to test (see README for how-to)
    const url: DatabaseUrlParsed = parseDatabaseUrl('jdbc:mysql://user:pass@host.com:3306/db')
    test.skip('getTableStats', async () => {
        const stats = await getTableStats(application, url, 'users')
        console.log('getTableStats', stats)
        expect(stats.rows).toEqual(2)
    })
    test.skip('getColumnStats', async () => {
        const stats = await getColumnStats(application, url, {table: 'users', column: 'name'})
        console.log('getColumnStats', stats)
        expect(stats.rows).toEqual(2)
    })
})
