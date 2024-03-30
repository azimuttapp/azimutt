import {describe, expect, test} from "@jest/globals";
import {ConnectorSchemaOpts, DatabaseUrlParsed, parseDatabaseUrl} from "@azimutt/database-model";
import {connect} from "../src/connect";
import {getBlockSize, getColumns, getDatabase, getSchema, getTables, getTypes} from "../src/postgres";
import {application, logger} from "./constants";

describe('postgres', () => {
    // local url, install db or replace it to test
    const url: DatabaseUrlParsed = parseDatabaseUrl('postgresql://postgres:postgres@localhost:5432/azimutt_dev')
    test.skip('getSchema', async () => {
        const opts: ConnectorSchemaOpts = {logger, logQueries: false, inferJsonAttributes: true, inferPolymorphicRelations: true}
        const schema = await connect(application, url, getSchema(opts), opts)
        console.log('schema', schema)
        // console.log('schema', schema.entities?.find(e => e.name == 'events')?.attrs?.find(a => a.name == 'name')?.stats)
        expect(schema.entities?.length).toEqual(14)
    })
    test.skip('getBlockSize', async () => {
        const opts: ConnectorSchemaOpts = {logger, logQueries: false}
        const blockSize = await connect(application, url, getBlockSize(opts), opts)
        console.log(`blockSize`, blockSize)
    })
    test.skip('getDatabase', async () => {
        const opts: ConnectorSchemaOpts = {logger, logQueries: false}
        const database = await connect(application, url, getDatabase(opts), opts)
        console.log(`database`, database)
    })
    test.skip('getTables', async () => {
        const opts: ConnectorSchemaOpts = {logger, logQueries: false}
        const tables = await connect(application, url, getTables(opts), opts)
        console.log(`${tables.length} tables`, tables)
    })
    test.skip('getColumns', async () => {
        const opts: ConnectorSchemaOpts = {logger, logQueries: false, schema: 'public', entity: 'events'}
        const columns = await connect(application, url, getColumns(opts), opts)
        console.log(`${columns.length} columns`, columns)
    })
    test.skip('getTypes', async () => {
        const opts: ConnectorSchemaOpts = {logger, logQueries: true, schema: 'public', entity: 'events'}
        const types = await connect(application, url, getTypes(opts), opts)
        console.log(`${types.length} types`, types)
    })
})
