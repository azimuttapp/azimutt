import {describe, expect, test} from "@jest/globals";
import {DatabaseUrlParsed, parseDatabaseUrl} from "@azimutt/database-types";
import {application} from "./constants";
import {getColumnStats, getTableStats} from "../src";

describe('stats', () => {
    // local url, install db or replace it to test
    const url: DatabaseUrlParsed = parseDatabaseUrl('postgresql://postgres:postgres@localhost:5432/azimutt_dev')
    test.skip('getTableStats', async () => {
        const stats = await getTableStats(application, url, 'public.users')
        expect(stats.rows).toEqual(2)
    })
    test.skip('getColumnStats', async () => {
        const stats = await getColumnStats(application, url, {table: 'public.users', column: 'name'})
        expect(stats.rows).toEqual(2)
    })
})
