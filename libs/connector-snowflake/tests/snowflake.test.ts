import {describe, expect, test} from "@jest/globals";
import {AzimuttSchema, DatabaseUrlParsed, parseDatabaseUrl} from "@azimutt/database-types";
import {application, logger} from "./constants";
import {execQuery} from "../src/common";
import {connect} from "../src/connect";
import {getColumns, getForeignKeys, getPrimaryKeys, getSchema, getTables, SnowflakeSchemaName} from "../src/snowflake";

describe('snowflake', () => {
    // local url, install db or replace it to test
    const url: DatabaseUrlParsed = parseDatabaseUrl('https://<user>:<pass>@<account>.snowflakecomputing.com/<database>')
    const schema: SnowflakeSchemaName | undefined = 'TPCDS_SF10TCL'

    test.skip('getSchema', async () => {
        const res = await connect(application, url, getSchema(schema, 10, false, logger))
        console.log('schema', res.tables[0])
        expect(res.tables.length).toEqual(24)
    }, 10000)
    test.skip('getTables', async () => {
        const res = await connect(application, url, conn => getTables(conn, schema, false, logger))
        console.log('tables', res.length, res)
        expect(res.length).toEqual(24)
    })
    test.skip('getColumns', async () => {
        const res = await connect(application, url, conn => getColumns(conn, schema, false, logger))
        console.log('columns', res.length, res)
        expect(res.length).toEqual(425)
    })
    test.skip('getPrimaryKeys', async () => {
        const res = await connect(application, url, conn => getPrimaryKeys(conn, schema, false, logger))
        console.log('primary keys', res.length, res)
        expect(res.length).toEqual(32)
    })
    test.skip('getForeignKeys', async () => {
        const res = await connect(application, url, conn => getForeignKeys(conn, schema, false, logger))
        console.log('foreign keys', res.length, res)
        expect(res.length).toEqual(108)
    })
})
