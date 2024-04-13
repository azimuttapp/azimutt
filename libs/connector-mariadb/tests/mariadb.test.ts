import {describe, expect, test} from "@jest/globals";
import {ConnectorSchemaOpts, DatabaseUrlParsed, parseDatabaseUrl} from "@azimutt/models";
import {connect} from "../src/connect";
import {execQuery} from "../src/query";
import {getSchema} from "../src/mariadb";
import {application, logger} from "./constants";

describe('mariadb', () => {
    // fake url, use a real one to test (see README for how-to)
    const url: DatabaseUrlParsed = parseDatabaseUrl('mariadb://user:pass@host.com:3306/db')
    const opts: ConnectorSchemaOpts = {logger, logQueries: false, inferJsonAttributes: true, inferPolymorphicRelations: true}

    test.skip('execQuery', async () => {
        const results = await connect(application, url, execQuery("SELECT * FROM airlines;", []), opts)
        console.log('results', results)
        expect(results.rows.length).toEqual(1)
    })
    test.skip('getSchema', async () => {
        const schema = await connect(application, url, getSchema(opts), opts)
        console.log('schema', schema)
        expect(schema.entities?.length).toEqual(6)
    })
})
