import {describe, expect, test} from "@jest/globals";
import {ConnectorSchemaOpts, DatabaseUrlParsed, parseDatabaseUrl} from "@azimutt/models";
import {connect} from "./connect";
import {execQuery} from "./query";
import {getColumns, getForeignKeyColumns, getPrimaryKeyColumns, getSchema, getTables} from "./snowflake";
import {application, logger} from "./constants.test";

describe('snowflake', () => {
    // fake url, use a real one to test (see README for how-to)
    const url: DatabaseUrlParsed = parseDatabaseUrl('snowflake://<user>:<pass>@<account>.snowflakecomputing.com?db=<database>')
    const opts: ConnectorSchemaOpts = {logger, logQueries: true, schema: 'TPCDS_SF10TCL', inferJsonAttributes: true, inferPolymorphicRelations: true}

    test.skip('execQuery', async () => {
        const query = `
        SELECT cc.CC_CALL_CENTER_SK, cc.CC_NAME, c.C_CUSTOMER_SK, c.C_EMAIL_ADDRESS, r.CR_REFUNDED_CASH
        FROM TPCDS_SF10TCL.CATALOG_RETURNS r
            JOIN TPCDS_SF10TCL.CALL_CENTER cc ON r.CR_CALL_CENTER_SK = cc.CC_CALL_CENTER_SK
            JOIN TPCDS_SF10TCL.CUSTOMER c ON r.CR_REFUNDED_CUSTOMER_SK = c.C_CUSTOMER_SK
        LIMIT 30;`
        const results = await connect(application, url, execQuery(query, []), {logger})
        console.log('results', results)
        expect(results.attributes).toEqual([
            {name: 'CC_CALL_CENTER_SK'},
            {name: 'CC_NAME'},
            {name: 'C_CUSTOMER_SK'},
            {name: 'C_EMAIL_ADDRESS'},
            {name: 'CR_REFUNDED_CASH'}
        ])
    })
    test.skip('getSchema', async () => {
        const schema = await connect(application, url, getSchema(opts), opts)
        console.log('schema', schema)
        expect(schema.entities?.length).toEqual(24)
    }, 10000)
    test.skip('getTables', async () => {
        const tables = await connect(application, url, getTables(opts), opts)
        console.log(`${tables.length} tables`, tables)
        expect(tables.length).toEqual(24)
    })
    test.skip('getColumns', async () => {
        const columns = await connect(application, url, getColumns(opts), opts)
        console.log(`${columns.length} columns`, columns)
        expect(columns.length).toEqual(425)
    })
    test.skip('getPrimaryKeyColumns', async () => {
        const primaryKeyCols = await connect(application, url, getPrimaryKeyColumns(opts), opts)
        console.log(`${primaryKeyCols.length} primary keys`, primaryKeyCols)
        expect(primaryKeyCols.length).toEqual(32)
    })
    test.skip('getForeignKeys', async () => {
        const foreignKeyColumns = await connect(application, url, getForeignKeyColumns(opts), opts)
        console.log(`${foreignKeyColumns.length} foreign keys`, foreignKeyColumns)
        expect(foreignKeyColumns.length).toEqual(108)
    })
})
