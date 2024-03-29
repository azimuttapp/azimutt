import {describe, expect, test} from "@jest/globals";
import {DatabaseUrlParsed, parseDatabaseUrl} from "@azimutt/database-types";
import {connect} from "../src/connect";
import {BigquerySchemaOpts, getSchema, getTables} from "../src/bigquery";
import {application, logger} from "./constants";
import {getColumns} from "../out/bigquery";

describe.skip('bigquery', () => {
    // fake url, use a real one to test (see README for how-to)
    const url: DatabaseUrlParsed = parseDatabaseUrl('bigquery://bigquery.googleapis.com/azimutt-experiments?key=local/key.json')
    test('getSchema', async () => {
        const opts: BigquerySchemaOpts = {logger, catalog: undefined, schema: 'relational', entity: 'azimutt_%', sampleSize: 10, inferRelations: true, ignoreErrors: false}
        const schema = await connect(application, url, getSchema(opts), {logger, logQueries: true})
        console.log('schema', schema)
        expect(schema.tables.length).toEqual(5)
    }, 15 * 1000)
    test('getTables', async () => {
        const projectId = 'azimutt-experiments'
        const datasetId = 'azimutt_connector_trial'
        const opts: BigquerySchemaOpts = {logger, catalog: undefined, schema: undefined, entity: undefined, sampleSize: 10, inferRelations: true, ignoreErrors: false}
        const tables = await connect(application, url, getTables(projectId, datasetId, opts), {logger, logQueries: true})
        console.log(`${tables.length} tables`, tables)
    })
    test('getColumns', async () => {
        const projectId = 'azimutt-experiments'
        const datasetId = 'azimutt_connector_trial'
        const opts: BigquerySchemaOpts = {logger, catalog: undefined, schema: undefined, entity: undefined, sampleSize: 10, inferRelations: true, ignoreErrors: false}
        const columns = await connect(application, url, getColumns(projectId, datasetId, opts), {logger, logQueries: true})
        console.log(`${columns.length} columns`, columns)
    })
})
