import {describe, expect, test} from "@jest/globals";
import {DatabaseUrlParsed, parseDatabaseUrl} from "@azimutt/database-model";
import {application, logger} from "./constants";
import {connect} from "../src/connect";
import {getColumnStats, getTableStats} from "../src/stats";

describe('stats', () => {
    // fake url, use a real one to test (see README for how-to)
    const url: DatabaseUrlParsed = parseDatabaseUrl('jdbc:mysql://user:pass@host.com:3306/db')
    test.skip('getTableStats', async () => {
        const stats = await connect(application, url, getTableStats({entity: 'users'}), {logger, logQueries: true})
        console.log('getTableStats', stats)
        expect(stats.rows).toEqual(2)
    })
    test.skip('getColumnStats', async () => {
        const stats = await connect(application, url, getColumnStats({entity: 'users', attribute: ['name']}), {logger, logQueries: true})
        console.log('getColumnStats', stats)
        expect(stats.rows).toEqual(2)
    })
})
