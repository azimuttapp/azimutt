import {describe, expect, test} from "@jest/globals";
import {ConnectorSchemaOpts, DatabaseUrlParsed, parseDatabaseUrl,} from "@azimutt/models";
import {connect} from "./connect";
import {execQuery} from "./query";
import {getBlockSize, getColumns, getDatabase, getDistinctValues, getSchema, getTables, getTypes,} from "./oracle";
import {application, logger} from "./constants.test";

describe('oracle', () => {
    // local url, install db or replace it to test
    const url: DatabaseUrlParsed = parseDatabaseUrl('jdbc:oracle:thin:sys/oracle@//localhost:1521/FREE')
    const opts: ConnectorSchemaOpts = {logger, logQueries: false, inferJsonAttributes: true, inferPolymorphicRelations: true}

    test.skip('execQuery', async () => {
        const query = 'SELECT u.id, e.id, o.id FROM users u JOIN events e ON u.id = e.created_by JOIN organizations o on o.id = e.organization_id FETCH FIRST 10 ROWS ONLY;'
        const results = await connect(application, url, execQuery(query, []), opts)
        expect(results.attributes).toEqual([
            {name: 'id', ref: {schema: 'public', entity: 'users', attribute: ['id']}},
            {name: 'id_2', ref: {schema: 'public', entity: 'events', attribute: ['id']}},
            {name: 'id_3', ref: {schema: 'public', entity: 'organizations', attribute: ['id']}},
        ])
    })
    test.skip('getSchema', async () => {
        const schema = await connect(application, url, getSchema(opts), opts)
        console.log('schema', schema)
        // console.log('schema', schema.entities?.find(e => e.name == 'events')?.attrs?.find(a => a.name == 'name')?.stats)
        expect(schema.entities?.length).toEqual(14)
    })
    test.skip('getBlockSize', async () => {
        const blockSize = await connect(application, url, getBlockSize(opts), opts)
        console.log(`blockSize`, blockSize)
    })
    test.skip('getDatabase', async () => {
        const database = await connect(application, url, getDatabase(opts), opts)
        console.log(`database`, database)
    })
    test.skip('getTables', async () => {
        const tables = await connect(application, url, getTables(opts), opts)
        console.log(`${tables.length} tables`, tables)
    })
    test.skip('getColumns', async () => {
        const columns = await connect(application, url, getColumns(opts), opts)
        console.log(`${columns.length} columns`, columns)
    })
    test.skip('getTypes', async () => {
        const types = await connect(application, url, getTypes(opts), opts)
        console.log(`${types.length} types`, types)
    })
    test.skip('getDistinctValues', async () => {
        const values = await connect(application, url, getDistinctValues({schema: 'C##AZIMUTT', entity: 'USERS'}, ['NAME'], opts), opts)
        console.log(`${values.length} values`, values)
    })
})
