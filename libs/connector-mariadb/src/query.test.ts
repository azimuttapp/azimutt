import {describe, expect, test} from "@jest/globals";
import {ConnectorSchemaOpts, DatabaseUrlParsed, parseDatabaseUrl} from "@azimutt/models";
import {connect} from "./connect";
import {execQuery} from "./query";
import {application, logger} from "./constants.test";

describe('query', () => {
    // fake url, use a real one to test (see README for how-to)
    const url: DatabaseUrlParsed = parseDatabaseUrl('mariadb://azimutt:azimutt@localhost:3307/mariadb_sample')
    const opts: ConnectorSchemaOpts = {logger, logQueries: false, inferJsonAttributes: true, inferPolymorphicRelations: true}

    test.skip('execQuery', async () => {
        const results = await connect(application, url, execQuery("SELECT * FROM users;", []), opts)
        console.log('results', results)
        expect(results.rows.length).toEqual(1)
    })
})
