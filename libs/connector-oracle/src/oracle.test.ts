import {describe, expect, test} from "@jest/globals";
import {DatabaseUrlParsed, parseDatabaseUrl} from "@azimutt/models";
import {connect} from "./connect";
import {
    getBlockSizes,
    getColumns,
    getConstraints,
    getDatabase,
    getDistinctValues,
    getIndexes,
    getRelations,
    getSampleValues,
    getSchema,
    getTables,
    getTypes,
    getViews,
} from "./oracle";
import {ScopeOpts} from "./helpers";
import {application, logger, oracleUsers} from "./constants.test";

describe('oracle', () => {
    // local url from [README](../README.md#local-setup), launch it or replace it to test
    const url: DatabaseUrlParsed = parseDatabaseUrl('oracle:thin:system/oracle@localhost:1521/FREE')
    const opts: ScopeOpts = {logger, logQueries: false, inferJsonAttributes: true, inferPolymorphicRelations: true, oracleUsers}

    test.skip('getSchema', async () => {
        const schema = await connect(application, url, getSchema(opts), opts)
        console.log('schema', schema)
        expect(schema.entities?.length).toEqual(7)
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
        expect(tables.length).toEqual(6)
    })
    test.skip('getViews', async () => {
        const views = await connect(application, url, getViews(opts), opts)
        console.log(`${views.length} views`, views)
        expect(views.length).toEqual(1)
    })
    test.skip('getColumns', async () => {
        const columns = await connect(application, url, getColumns(opts), opts)
        console.log(`${columns.length} columns`, columns)
        expect(columns.length).toEqual(28)
    })
    test.skip('getConstraints', async () => {
        const constraints = await connect(application, url, getConstraints(opts), opts)
        console.log(`${constraints.length} constraints`, constraints)
        expect(constraints.length).toEqual(12)
    })
    test.skip('getIndexes', async () => {
        const indexes = await connect(application, url, getIndexes(opts), opts)
        console.log(`${indexes.length} indexes`, indexes)
        expect(indexes.length).toEqual(4)
    })
    test.skip('getRelations', async () => {
        const relations = await connect(application, url, getRelations(opts), opts)
        console.log(`${relations.length} relations`, relations)
        expect(relations.length).toEqual(7)
    })
    test.skip('getTypes', async () => {
        const types = await connect(application, url, getTypes(opts), opts)
        console.log(`${types.length} types`, types)
        expect(types.length).toEqual(2)
    })
    test.skip('getSampleValues', async () => {
        const values = await connect(application, url, getSampleValues({schema: 'C##AZIMUTT', entity: 'USERS'}, ['SETTINGS'], opts), opts)
        console.log(`${values.length} values`, values)
        expect(values.length).toEqual(1)
    })
    test.skip('getDistinctValues', async () => {
        const values = await connect(application, url, getDistinctValues({schema: 'C##AZIMUTT', entity: 'USERS'}, ['NAME'], opts), opts)
        console.log(`${values.length} values`, values)
        expect(values.length).toEqual(3)
    })
})
