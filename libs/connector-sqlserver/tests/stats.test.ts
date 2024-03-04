import {describe, expect, test} from "@jest/globals";
import {DatabaseUrlParsed, parseDatabaseUrl} from "@azimutt/database-types";
import {application, opts} from "./constants";
import {connect} from "../src/connect";
import {getColumnStats, getTableStats} from "../src/stats";

describe('stats', () => {
    // fake url, use a real one to test (see README for how-to)
    const url: DatabaseUrlParsed = parseDatabaseUrl('Server=host.com,1433;Database=db;User Id=user;Password=pass')
    test.skip('getTableStats', async () => {
        const stats = await connect(application, url, getTableStats('SalesLT.Customer'), opts)
        console.log('getTableStats', stats)
        expect(stats.rows).toEqual(847)
    })
    test.skip('getColumnStats', async () => {
        const stats = await connect(application, url, getColumnStats({table: 'SalesLT.Customer', column: 'FirstName'}), opts)
        console.log('getColumnStats', stats)
        expect(stats.rows).toEqual(847)
    })
})
