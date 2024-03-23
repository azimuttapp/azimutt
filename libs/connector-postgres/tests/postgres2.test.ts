import {describe, expect, test} from "@jest/globals";
import {ConnectorSchemaOpts, DatabaseUrlParsed, parseDatabaseUrl} from "@azimutt/database-model";
import {application, logger} from "./constants";
import {connect} from "../src/connect";
import {getBlockSize, getColumns, getDatabase, getSchema, getTables, getTypes} from "../src/postgres2";

describe.skip('postgres2', () => {
    // local url, install db or replace it to test
    const url: DatabaseUrlParsed = parseDatabaseUrl('postgresql://postgres:postgres@localhost:5432/azimutt_dev')
    test('getSchema', async () => {
        const opts: ConnectorSchemaOpts = {logger, logQueries: false, inferJsonAttributes: true, inferPolymorphicRelations: true}
        const schema = await connect(application, url, getSchema(opts), opts)
        console.log('schema', schema)
        // console.log('schema', schema.entities?.find(e => e.name == 'events')?.attrs?.find(a => a.name == 'name')?.stats)
        expect(schema.entities?.length).toEqual(14)
    })
    test('getBlockSize', async () => {
        const opts: ConnectorSchemaOpts = {logger, logQueries: false}
        const blockSize = await connect(application, url, getBlockSize(opts), opts)
        console.log(`blockSize`, blockSize)
    })
    test('getDatabase', async () => {
        const opts: ConnectorSchemaOpts = {logger, logQueries: false}
        const database = await connect(application, url, getDatabase(opts), opts)
        console.log(`database`, database)
    })
    test('getTables', async () => {
        const opts: ConnectorSchemaOpts = {logger, logQueries: false}
        const tables = await connect(application, url, getTables(opts), opts)
        console.log(`${tables.length} tables`, tables)
    })
    test('getColumns', async () => {
        const opts: ConnectorSchemaOpts = {logger, logQueries: false, schema: 'public', entity: 'events'}
        const columns = await connect(application, url, getColumns(opts), opts)
        console.log(`${columns.length} columns`, columns)
    })
    test('getTypes', async () => {
        const opts: ConnectorSchemaOpts = {logger, logQueries: true, schema: 'public', entity: 'events'}
        const types = await connect(application, url, getTypes(opts), opts)
        console.log(`${types.length} types`, types)
    })
})
