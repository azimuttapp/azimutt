import {describe, expect, test} from "@jest/globals";
import {DatabaseUrlParsed, parseDatabaseUrl} from "@azimutt/database-types";
import {application} from "./constants";
import {connect} from "../src/connect";
import {getColumnStats, getTableStats} from "../src/stats";

describe('stats', () => {
    // fake url, use a real one to test (see README for how-to)
    const url: DatabaseUrlParsed = parseDatabaseUrl('mariadb://user:pass@host.com:3306/db')
    test.skip('getTableStats', async () => {
        const stats = await connect(application, url, getTableStats('users'))
        console.log('getTableStats', stats)
        expect(stats.rows).toEqual(2)
    })
    test.skip('getColumnStats', async () => {
        const stats = await connect(application, url, getColumnStats({table: 'users', column: 'name'}))
        console.log('getColumnStats', stats)
        expect(stats.rows).toEqual(2)
    })
})
