import {describe, expect, test} from "@jest/globals";
import {ConnectorSchemaOpts, DatabaseUrlParsed, parseDatabaseUrl} from "@azimutt/models";
import {connect} from "./connect";
import {execQuery} from "./query";
import {application, logger} from "./constants.test";

describe('query', () => {
    // local url from [README](../README.md#local-setup), launch it or replace it to test
    const url: DatabaseUrlParsed = parseDatabaseUrl('mariadb://azimutt:azimutt@localhost:3307/mariadb_sample')
    const opts: ConnectorSchemaOpts = {logger, logQueries: false, inferJsonAttributes: true, inferPolymorphicRelations: true}

    test.skip('execQuery', async () => {
        const query = 'SELECT id, name FROM users LIMIT 10;'
        const results = await connect(application, url, execQuery(query, []), opts)
        console.log('results', results)
        expect(results.rows.length).toEqual(3)
        expect(results.attributes).toEqual([
            {name: 'id', ref: {schema: 'mariadb_sample', entity: 'users', attribute: ['id']}},
            {name: 'name', ref: {schema: 'mariadb_sample', entity: 'users', attribute: ['name']}},
        ])
    })
})
