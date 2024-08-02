import {describe, expect, test} from "@jest/globals";
import {DatabaseUrlParsed, parseDatabaseUrl} from "@azimutt/models";
import {connect} from "./connect";
import {getColumnStats, getTableStats} from "./stats";
import {application, logger} from "./constants.test";

describe('stats', () => {
    // fake url, use a real one to test (see README for how-to)
    const url: DatabaseUrlParsed = parseDatabaseUrl('mysql://azimutt:azimutt@localhost:3306/mysql_sample')

    test.skip('getTableStats', async () => {
        const stats = await connect(application, url, getTableStats({entity: 'users'}), {logger, logQueries: true})
        console.log('getTableStats', stats)
        expect(stats.rows).toEqual(3)
    })
    test.skip('getColumnStats', async () => {
        const stats = await connect(application, url, getColumnStats({entity: 'users', attribute: ['name']}), {logger, logQueries: true})
        console.log('getColumnStats', stats)
        expect(stats.rows).toEqual(3)
    })
})
