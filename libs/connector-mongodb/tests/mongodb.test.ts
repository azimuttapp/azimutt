import {describe, expect, test} from "@jest/globals";
import {ConnectorSchemaOpts, DatabaseUrlParsed, parseDatabaseUrl} from "@azimutt/models";
import {connect} from "../src/connect";
import {execQuery} from "../src/query";
import {getSchema} from "../src/mongodb";
import {application, logger} from "./constants";

// to have at least one test in every module ^^
describe('mongodb', () => {
    // fake url, use a real one to test (see README for how-to)
    const url: DatabaseUrlParsed = parseDatabaseUrl('mongodb+srv://user:password@cluster2.gu2a9mr.mongodb.net')
    const opts: ConnectorSchemaOpts = {logger, logQueries: false, inferJsonAttributes: true, inferPolymorphicRelations: true}

    test.skip('execQuery', async () => {
        const results = await connect(application, url, execQuery('sample_mflix/movies/find/{"runtime":{"$eq":1}}', []), opts)
        console.log('results', results)
        expect(results.rows.length).toEqual(6)
    })
    test.skip('getSchema', async () => {
        const schema = await connect(application, url, getSchema(opts), opts)
        console.log('schema', schema)
        expect(schema.entities?.length).toEqual(22)
    })
})
