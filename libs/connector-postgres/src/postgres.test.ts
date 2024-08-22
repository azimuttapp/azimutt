import {describe, expect, test} from "@jest/globals";
import {ConnectorSchemaOpts, DatabaseUrlParsed, parseDatabaseUrl} from "@azimutt/models";
import {connect} from "./connect";
import {getBlockSize, getColumns, getDatabase, getDistinctValues, getSchema, getTables, getTypes} from "./postgres";
import {application, logger} from "./constants.test";

describe('postgres', () => {
    // local url from [README](../README.md#local-setup), launch it or replace it to test
    const url: DatabaseUrlParsed = parseDatabaseUrl('postgresql://postgres:postgres@localhost:5433/postgres')
    const opts: ConnectorSchemaOpts = {logger, logQueries: false, inferJsonAttributes: true, inferPolymorphicRelations: true}

    test.skip('getSchema', async () => {
        const schema = await connect(application, url, getSchema(opts), opts)
        console.log('schema', schema)
        expect(schema.entities?.length).toEqual(7)
    })
    test.skip('getBlockSize', async () => {
        const blockSize = await connect(application, url, getBlockSize(opts), opts)
        console.log(`blockSize`, blockSize)
    })
    test.skip('getDatabase', async () => {
        const database = await connect(application, url, getDatabase(opts), opts)
        console.log(`database`, database)
        expect(database.database).toEqual('postgres')
    })
    test.skip('getTables', async () => {
        const tables = await connect(application, url, getTables(opts), opts)
        console.log(`${tables.length} tables`, tables)
        expect(tables.length).toEqual(7)
    })
    test.skip('getColumns', async () => {
        const columns = await connect(application, url, getColumns(opts), opts)
        console.log(`${columns.length} columns`, columns)
        expect(columns.length).toEqual(28)
    })
    test.skip('getTypes', async () => {
        const types = await connect(application, url, getTypes(opts), opts)
        console.log(`${types.length} types`, types)
        expect(types.length).toEqual(0)
    })
    test.skip('getDistinctValues', async () => {
        const values = await connect(application, url, getDistinctValues({schema: 'public', entity: 'users'}, ['name'], opts), opts)
        console.log(`${values.length} values`, values)
        expect(values.length).toEqual(3)
    })
})
