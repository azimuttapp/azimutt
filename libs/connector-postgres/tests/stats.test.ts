import {describe, expect, test} from "@jest/globals";
import {DatabaseUrlParsed, parseDatabaseUrl} from "@azimutt/database-types";
import {application, opts} from "./constants";
import {connect} from "../src/connect";
import {getColumnStats, getTableStats} from "../src/stats";

describe('stats', () => {
    // local url, install db or replace it to test
    const url: DatabaseUrlParsed = parseDatabaseUrl('postgresql://postgres:postgres@localhost:5432/azimutt_dev')
    test.skip('getTableStats', async () => {
        const stats = await connect(application, url, getTableStats('public.users'), opts)
        console.log('getTableStats', stats)
        expect(stats.rows).toEqual(2)
    })
    test.skip('getColumnStats', async () => {
        const stats = await connect(application, url, getColumnStats({table: 'public.users', column: 'name'}), opts)
        console.log('getColumnStats', stats)
        expect(stats.rows).toEqual(3)
    })
})
