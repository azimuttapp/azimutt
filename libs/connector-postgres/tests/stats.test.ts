import {describe, expect, test} from "@jest/globals";
import {DatabaseUrlParsed, parseDatabaseUrl} from "@azimutt/models";
import {connect} from "../src/connect";
import {getColumnStats, getTableStats} from "../src/stats";
import {application, logger} from "./constants";

describe('stats', () => {
    // local url, install db or replace it to test
    const url: DatabaseUrlParsed = parseDatabaseUrl('postgresql://postgres:postgres@localhost:5432/azimutt_dev')

    test.skip('getTableStats', async () => {
        const stats = await connect(application, url, getTableStats({schema: 'public', entity: 'users'}), {logger, logQueries: true})
        console.log('getTableStats', stats)
        expect(stats.rows).toEqual(2)
    })
    test.skip('getColumnStats', async () => {
        const stats = await connect(application, url, getColumnStats({schema: 'public', entity: 'users', attribute: ['name']}), {logger, logQueries: true})
        console.log('getColumnStats', stats)
        expect(stats.rows).toEqual(3)
    })
})
