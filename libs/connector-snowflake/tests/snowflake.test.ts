import {describe, expect, test} from "@jest/globals";
import {ConnectorSchemaOpts, DatabaseUrlParsed, parseDatabaseUrl} from "@azimutt/database-model";
import {connect} from "../src/connect";
import {getColumns, getForeignKeyColumns, getPrimaryKeyColumns, getSchema, getTables} from "../src/snowflake";
import {application, logger} from "./constants";

describe('snowflake', () => {
    // local url, install db or replace it to test
    const url: DatabaseUrlParsed = parseDatabaseUrl('snowflake://<user>:<pass>@<account>.snowflakecomputing.com?db=<database>')
    const opts: ConnectorSchemaOpts = {logger, logQueries: true, schema: 'TPCDS_SF10TCL', inferJsonAttributes: true, inferPolymorphicRelations: true}

    test.skip('getSchema', async () => {
        const schema = await connect(application, url, getSchema(opts), opts)
        console.log('schema', schema)
        expect(schema.entities.length).toEqual(24)
    }, 10000)
    test.skip('getTables', async () => {
        const tables = await connect(application, url, getTables(opts), opts)
        console.log('tables', tables.length, tables)
        expect(tables.length).toEqual(24)
    })
    test.skip('getColumns', async () => {
        const columns = await connect(application, url, getColumns(opts), opts)
        console.log('columns', columns.length, columns)
        expect(columns.length).toEqual(425)
    })
    test.skip('getPrimaryKeyColumns', async () => {
        const primaryKeyCols = await connect(application, url, getPrimaryKeyColumns(opts), opts)
        console.log('primary keys', primaryKeyCols.length, primaryKeyCols)
        expect(primaryKeyCols.length).toEqual(32)
    })
    test.skip('getForeignKeys', async () => {
        const foreignKeyColumns = await connect(application, url, getForeignKeyColumns(opts), opts)
        console.log('foreign keys', foreignKeyColumns.length, foreignKeyColumns)
        expect(foreignKeyColumns.length).toEqual(108)
    })
})
