import {describe, expect, test} from "@jest/globals";
import {DatabaseUrlParsed, parseDatabaseUrl} from "@azimutt/database-types";
import {connect} from "../src/connect";
import {BigquerySchemaOpts, getForeignKeys, getIndexes, getPrimaryKeys, getSchema, getTables} from "../src/bigquery";
import {application, logger} from "./constants";
import {getColumns} from "../out/bigquery";

describe.skip('bigquery', () => {
    // fake url, use a real one to test (see README for how-to)
    const project = 'azimutt-experiments'
    const dataset = 'relational'
    const table = 'azimutt_%'
    const url: DatabaseUrlParsed = parseDatabaseUrl(`bigquery://bigquery.googleapis.com/${project}?key=local/key.json`)
    const opts: BigquerySchemaOpts = {logger, catalog: project, schema: dataset, entity: table, sampleSize: 10, inferRelations: true, ignoreErrors: false}

    test('getSchema', async () => {
        const schema = await connect(application, url, getSchema(opts), {logger, logQueries: true})
        console.log('schema', schema)
        expect(schema.tables.length).toEqual(5)
    }, 15 * 1000)
    test('getTables', async () => {
        const tables = await connect(application, url, getTables(project, dataset, opts), {logger, logQueries: true})
        console.log(`${tables.length} tables`, tables)
    })
    test('getColumns', async () => {
        const columns = await connect(application, url, getColumns(project, dataset, opts), {logger, logQueries: true})
        console.log(`${columns.length} columns`, columns)
    })
    test('getPrimaryKeys', async () => {
        const primaryKeys = await connect(application, url, getPrimaryKeys(project, dataset, opts), {logger, logQueries: true})
        console.log(`${primaryKeys.length} primary keys`, primaryKeys)
    })
    test('getForeignKeys', async () => {
        const foreignKeys = await connect(application, url, getForeignKeys(project, dataset, opts), {logger, logQueries: true})
        console.log(`${foreignKeys.length} foreign keys`, foreignKeys)
    })
    test('getIndexes', async () => {
        const indexes = await connect(application, url, getIndexes(project, dataset, opts), {logger, logQueries: true})
        console.log(`${indexes.length} indexes`, indexes)
    })
})
