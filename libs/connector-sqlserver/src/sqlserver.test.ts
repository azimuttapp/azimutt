import {describe, expect, test} from "@jest/globals";
import {ConnectorSchemaOpts, DatabaseUrlParsed, parseDatabaseUrl} from "@azimutt/models";
import {connect} from "./connect";
import {getComments, getSchema} from "./sqlserver";
import {application, logger} from "./constants.test";

describe('sqlserver', () => {
    // local url from [README](../README.md#local-setup), launch it or replace it to test
    const url: DatabaseUrlParsed = parseDatabaseUrl('sqlserver://sa:azimutt_42@localhost:1433/master')
    const opts: ConnectorSchemaOpts = {logger, logQueries: false, inferJsonAttributes: true, inferPolymorphicRelations: true}

    test.skip('getSchema', async () => {
        const schema = await connect(application, url, getSchema(opts), opts)
        console.log('schema', schema)
        expect(schema.entities?.length).toEqual(13)
    })
    test.skip('getComments', async () => {
        const comments = await connect(application, url, getComments(opts), opts)
        console.log(`${comments.length} comments`, comments)
        expect(comments.length).toEqual(4)
    })
})
