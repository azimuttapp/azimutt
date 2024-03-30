import {describe, expect, test} from "@jest/globals";
import {ConnectorSchemaOpts, DatabaseUrlParsed, parseDatabaseUrl} from "@azimutt/database-model";
import {application, logger} from "./constants";
import {connect} from "../src/connect";
import {getSchema} from "../src/sqlserver";

describe('sqlserver', () => {
    // fake url, use a real one to test (see README for how-to)
    const url: DatabaseUrlParsed = parseDatabaseUrl('Server=host.com,1433;Database=db;User Id=user;Password=pass')
    test.skip('getSchema', async () => {
        const opts: ConnectorSchemaOpts = {logger, logQueries: true, inferJsonAttributes: true, inferPolymorphicRelations: true}
        const schema = await connect(application, url, getSchema(opts), opts)
        console.log('schema', schema)
        expect(schema.entities?.length).toEqual(32)
    })
})
