import {describe, expect, test} from "@jest/globals";
import {DatabaseUrlParsed, parseDatabaseUrl} from "@azimutt/database-types";
import {application, opts} from "./constants";
import {connect} from "../src/connect";
import {getColumnStats, getTableStats} from "../src/stats";

describe('stats', () => {
    // local url, install db or replace it to test
    const url: DatabaseUrlParsed = parseDatabaseUrl('snowflake://<user>:<pass>@<account>.snowflakecomputing.com?db=<database>')

    test.skip('getTableStats', async () => {
        const stats = await connect(application, url, getTableStats('TPCDS_SF10TCL.CUSTOMER'), opts)
        console.log('getTableStats', stats)
        expect(stats.rows).toEqual(65000000)
    })
    test.skip('getColumnStats', async () => {
        const stats = await connect(application, url, getColumnStats({table: 'TPCDS_SF10TCL.CUSTOMER', column: 'C_FIRST_NAME'}), opts)
        console.log('getColumnStats', stats)
        expect(stats.rows).toEqual(65000000)
    })
})
