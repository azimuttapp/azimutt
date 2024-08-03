import {describe, expect, test} from "@jest/globals";
import {ConnectorSchemaOpts, DatabaseUrlParsed, parseDatabaseUrl} from "@azimutt/models";
import {connect} from "./connect";
import {getSchema} from "./mongodb";
import {application, logger} from "./constants.test";

describe('mongodb', () => {
    // local url from [README](../README.md#local-setup), launch it or replace it to test
    const url: DatabaseUrlParsed = parseDatabaseUrl('mongodb://localhost:27017/mongo_sample')
    const opts: ConnectorSchemaOpts = {logger, logQueries: false, database: url.db, inferJsonAttributes: true, inferPolymorphicRelations: true}

    test.skip('getSchema', async () => {
        const schema = await connect(application, url, getSchema(opts), opts)
        console.log('schema', schema)
        expect(schema.entities?.length).toEqual(3)
    })
})
