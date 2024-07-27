import {describe, expect, test} from "@jest/globals";
import {DatabaseUrlParsed, parseDatabaseUrl,} from "@azimutt/models";
import {connect} from "./connect";
import {execQuery} from "./query";
import {
    getBlockSizes,
    getColumns,
    getConstraints,
    getDatabase,
    getDistinctValues,
    getIndexes,
    getRelations,
    getSchema,
    getTables,
    getTypes,
    getViews,
} from "./oracle";
import {application, logger, oracleUsers} from "./constants.test";
import {ScopeOpts} from "./helpers";

describe('oracle', () => {
    // local url, install db or replace it to test
    const url: DatabaseUrlParsed = parseDatabaseUrl('oracle:thin:system/oracle@localhost:1521')
    const opts: ScopeOpts = {logger, logQueries: false, inferJsonAttributes: true, inferPolymorphicRelations: true, oracleUsers}

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
        console.log(`${(schema.entities || []).length} entities`, ...(schema.entities || []))
        console.log(`${(schema.relations || []).length} relations`, ...(schema.relations || []))
        console.log(`${(schema.types || []).length} types`, ...(schema.types || []))
        console.log('stats', schema.stats)
        // console.log('schema', schema.entities?.find(e => e.name == 'events')?.attrs?.find(a => a.name == 'name')?.stats)
        expect(schema.entities?.length).toEqual(14)
    }, 15000)
    test.skip('getDatabase', async () => {
        const database = await connect(application, url, getDatabase(opts), opts)
        console.log(`database`, database)
    })
    test.skip('getBlockSizes', async () => {
        const blockSizes = await connect(application, url, getBlockSizes(opts), opts)
        console.log(`blockSizes`, blockSizes)
    })
    test.skip('getTables', async () => {
        const tables = await connect(application, url, getTables(opts), opts)
        console.log(`${tables.length} tables`, tables)
    })
    test.skip('getViews', async () => {
        const views = await connect(application, url, getViews(opts), opts)
        console.log(`${views.length} views`, views)
    })
    test.skip('getColumns', async () => {
        const columns = await connect(application, url, getColumns(opts), opts)
        console.log(`${columns.length} columns`, columns)
    })
    test.skip('getConstraints', async () => {
        const constraints = await connect(application, url, getConstraints(opts), opts)
        console.log(`${constraints.length} constraints`, constraints)
    })
    test.skip('getIndexes', async () => {
        const indexes = await connect(application, url, getIndexes(opts), opts)
        console.log(`${indexes.length} indexes`, indexes)
    })
    test.skip('getRelations', async () => {
        const relations = await connect(application, url, getRelations(opts), opts)
        console.log(`${relations.length} relations`, relations)
    })
    test.skip('getTypes', async () => {
        const types = await connect(application, url, getTypes(opts), opts)
        console.log(`${types.length} types`, types)
    })
    // TODO getSampleValues
    test.skip('getDistinctValues', async () => {
        const values = await connect(application, url, getDistinctValues({schema: 'C##AZIMUTT', entity: 'USERS'}, ['NAME'], opts), opts)
        console.log(`${values.length} values`, values)
    })
})
