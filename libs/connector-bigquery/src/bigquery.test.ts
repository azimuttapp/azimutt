import {describe, expect, test} from "@jest/globals";
import {ConnectorSchemaOpts, DatabaseUrlParsed, parseDatabaseUrl} from "@azimutt/models";
import {connect} from "./connect";
import {execQuery} from "./query";
import {getColumns, getForeignKeys, getIndexes, getPrimaryKeys, getSchema, getTables} from "./bigquery";
import {application, logger} from "./constants.test";

describe('bigquery', () => {
    // fake url, use a real one to test (see README for how-to)
    const project = 'azimutt-experiments'
    const dataset = 'relational'
    const table = 'azimutt_%'
    const url: DatabaseUrlParsed = parseDatabaseUrl(`bigquery://bigquery.googleapis.com/${project}?key=local/key.json`)
    const opts: ConnectorSchemaOpts = {logger, catalog: project, schema: dataset, entity: table, sampleSize: 10, inferRelations: true, ignoreErrors: false}

    test.skip('query', async () => {
        const query = 'SELECT * FROM azimutt_connector_trial.azimutt_biggest_users WHERE string_field_0 = ? LIMIT 10;'
        const params = ['HumanTalks Paris orga']
        const results = await connect(application, url, execQuery(query, params), opts)
        console.log('results', results)
    })
    test.skip('getSchema', async () => {
        const schema = await connect(application, url, getSchema(opts), opts)
        console.log('schema', schema)
        expect(schema.entities?.length).toEqual(8)
    }, 15 * 1000)
    test.skip('getTables', async () => {
        const tables = await connect(application, url, getTables(project, dataset, opts), opts)
        console.log(`${tables.length} tables`, tables)
    })
    test.skip('getColumns', async () => {
        const columns = await connect(application, url, getColumns(project, dataset, opts), opts)
        console.log(`${columns.length} columns`, columns)
    })
    test.skip('getPrimaryKeys', async () => {
        const primaryKeys = await connect(application, url, getPrimaryKeys(project, dataset, opts), opts)
        console.log(`${primaryKeys.length} primary keys`, primaryKeys)
    })
    test.skip('getForeignKeys', async () => {
        const foreignKeys = await connect(application, url, getForeignKeys(project, dataset, opts), opts)
        console.log(`${foreignKeys.length} foreign keys`, foreignKeys)
    })
    test.skip('getIndexes', async () => {
        const indexes = await connect(application, url, getIndexes(project, dataset, opts), opts)
        console.log(`${indexes.length} indexes`, indexes)
    })
})
