import {describe, expect, test} from "@jest/globals";
import {DatabaseUrlParsed, parseDatabaseUrl} from "@azimutt/database-types";
import {application, opts} from "./constants";
import {connect} from "../src/connect";
import {execQuery} from "../src/common";

describe('query', () => {
    // local url, install db or replace it to test
    const url: DatabaseUrlParsed = parseDatabaseUrl('snowflake://<user>:<pass>@<account>.snowflakecomputing.com?db=<database>')

    test.skip('query', async () => {
        const query = `
        SELECT cc.CC_CALL_CENTER_SK, cc.CC_NAME, c.C_CUSTOMER_SK, c.C_EMAIL_ADDRESS, r.CR_REFUNDED_CASH
        FROM TPCDS_SF10TCL.CATALOG_RETURNS r
            JOIN TPCDS_SF10TCL.CALL_CENTER cc ON r.CR_CALL_CENTER_SK = cc.CC_CALL_CENTER_SK
            JOIN TPCDS_SF10TCL.CUSTOMER c ON r.CR_REFUNDED_CUSTOMER_SK = c.C_CUSTOMER_SK
        LIMIT 30;`
        const results = await connect(application, url, execQuery(query, []), opts)
        expect(results.columns).toEqual([
            {name: 'CC_CALL_CENTER_SK'},
            {name: 'CC_NAME'},
            {name: 'C_CUSTOMER_SK'},
            {name: 'C_EMAIL_ADDRESS'},
            {name: 'CR_REFUNDED_CASH'}
        ])
    })
})
