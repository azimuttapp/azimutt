import {describe, expect, test} from "@jest/globals";
import {DatabaseUrlParsed, parseDatabaseUrl} from "@azimutt/database-model";
import {connect} from "../src/connect";
import {
    BigquerySchemaOpts,
    getColumns,
    getForeignKeys,
    getIndexes,
    getPrimaryKeys,
    getSchema,
    getTables
} from "../src/bigquery";
import {application, logger} from "./constants";

describe('bigquery', () => {
    // fake url, use a real one to test (see README for how-to)
    const project = 'azimutt-experiments'
    const dataset = 'relational'
    const table = 'azimutt_%'
    const url: DatabaseUrlParsed = parseDatabaseUrl(`bigquery://bigquery.googleapis.com/${project}?key=local/key.json`)
    const opts: BigquerySchemaOpts = {logger, catalog: project, schema: dataset, entity: table, sampleSize: 10, inferRelations: true, ignoreErrors: false}

    test.skip('getSchema', async () => {
        const schema = await connect(application, url, getSchema(opts), {logger, logQueries: true})
        console.log('schema', schema)
        expect(schema.tables.length).toEqual(8)
    }, 15 * 1000)
    test.skip('getTables', async () => {
        const tables = await connect(application, url, getTables(project, dataset, opts), {logger, logQueries: true})
        console.log(`${tables.length} tables`, tables)
    })
    test.skip('getColumns', async () => {
        const columns = await connect(application, url, getColumns(project, dataset, opts), {logger, logQueries: true})
        console.log(`${columns.length} columns`, columns)
    })
    test.skip('getPrimaryKeys', async () => {
        const primaryKeys = await connect(application, url, getPrimaryKeys(project, dataset, opts), {logger, logQueries: true})
        console.log(`${primaryKeys.length} primary keys`, primaryKeys)
    })
    test.skip('getForeignKeys', async () => {
        const foreignKeys = await connect(application, url, getForeignKeys(project, dataset, opts), {logger, logQueries: true})
        console.log(`${foreignKeys.length} foreign keys`, foreignKeys)
    })
    test.skip('getIndexes', async () => {
        const indexes = await connect(application, url, getIndexes(project, dataset, opts), {logger, logQueries: true})
        console.log(`${indexes.length} indexes`, indexes)
    })
})
