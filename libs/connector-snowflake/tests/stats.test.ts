import {describe, expect, test} from "@jest/globals";
import {DatabaseUrlParsed, parseDatabaseUrl} from "@azimutt/database-model";
import {connect} from "../src/connect";
import {getColumnStats, getTableStats} from "../src/stats";
import {application, logger} from "./constants";

describe('stats', () => {
    // fake url, use a real one to test (see README for how-to)
    const url: DatabaseUrlParsed = parseDatabaseUrl('snowflake://<user>:<pass>@<account>.snowflakecomputing.com?db=<database>')

    test.skip('getTableStats', async () => {
        const stats = await connect(application, url, getTableStats({schema: 'TPCDS_SF10TCL', entity: 'CUSTOMER'}), {logger, logQueries: true})
        console.log('getTableStats', stats)
        expect(stats.rows).toEqual(65000000)
    })
    test.skip('getColumnStats', async () => {
        const stats = await connect(application, url, getColumnStats({schema: 'TPCDS_SF10TCL', entity: 'CUSTOMER', attribute: ['C_FIRST_NAME']}), {logger, logQueries: true})
        console.log('getColumnStats', stats)
        expect(stats.rows).toEqual(65000000)
    })
})
