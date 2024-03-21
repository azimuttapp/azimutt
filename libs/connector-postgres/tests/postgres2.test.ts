import {describe, expect, test} from "@jest/globals";
import {DatabaseUrlParsed, parseDatabaseUrl} from "@azimutt/database-types";
import {application, logger} from "./constants";
import {connect} from "../src/connect";
import {getColumns, getSchema, getTables} from "../src/postgres2";
import {ConnectorSchemaOpts} from "@azimutt/database-model";

describe.skip('postgres2', () => {
    // local url, install db or replace it to test
    const url: DatabaseUrlParsed = parseDatabaseUrl('postgresql://postgres:postgres@localhost:5432/azimutt_dev')
    test('getSchema', async () => {
        const opts: ConnectorSchemaOpts = {logger, logQueries: true}
        const schema = await connect(application, url, getSchema(opts), opts)
        console.log('schema', schema)
        expect(schema.entities?.length).toEqual(14)
    })
    test('getTables', async () => {
        const opts: ConnectorSchemaOpts = {logger, logQueries: true}
        const tables = await connect(application, url, getTables(opts), opts)
        console.log(`${tables.length} tables`, tables)
    })
    test('getColumns', async () => {
        const opts: ConnectorSchemaOpts = {logger, logQueries: false, schema: 'public', entity: 'events'}
        const columns = await connect(application, url, getColumns(opts), opts)
        console.log(`${columns.length} columns`, columns)
    })
})
