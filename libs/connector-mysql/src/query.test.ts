import {describe, expect, test} from "@jest/globals";
import {ConnectorSchemaOpts, DatabaseUrlParsed, parseDatabaseUrl} from "@azimutt/models";
import {connect} from "./connect";
import {execQuery} from "./query";
import {application, logger} from "./constants.test";

describe('query', () => {
    // local url from [README](../README.md#local-setup), launch it or replace it to test
    const url: DatabaseUrlParsed = parseDatabaseUrl('mysql://azimutt:azimutt@localhost:3306/mysql_sample')
    const opts: ConnectorSchemaOpts = {logger, logQueries: false, inferJsonAttributes: true, inferPolymorphicRelations: true}

    test.skip('execQuery', async () => {
        const query = 'SELECT id, name, settings FROM users LIMIT 10;'
        const results = await connect(application, url, execQuery(query, []), opts)
        console.log('results', results)
        expect(results.rows.length).toEqual(3)
        expect(results.attributes).toEqual([
            {name: 'id', ref: {entity: 'users', attribute: ['id']}},
            {name: 'name', ref: {entity: 'users', attribute: ['name']}},
            {name: 'settings', ref: {entity: 'users', attribute: ['settings']}},
        ])
    })
})
