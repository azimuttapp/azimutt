import {describe, expect, test} from "@jest/globals";
import {ConnectorSchemaOpts, DatabaseUrlParsed, parseDatabaseUrl} from "@azimutt/models";
import {connect} from "./connect";
import {execQuery} from "./query";
import {application, logger} from "./constants.test";

describe('query', () => {
    // local url from [README](../README.md#local-setup), launch it or replace it to test
    const url: DatabaseUrlParsed = parseDatabaseUrl('sqlserver://sa:azimutt_42@localhost:1433/master')
    const opts: ConnectorSchemaOpts = {logger, logQueries: false, inferJsonAttributes: true, inferPolymorphicRelations: true}

    test.skip('execQuery', async () => {
        const query = 'SELECT TOP 10 id, name FROM users;'
        const results = await connect(application, url, execQuery(query, []), opts)
        console.log('results', results)
        expect(results.rows.length).toEqual(3)
        expect(results.attributes).toEqual([
            {name: 'id'/*, ref: {schema: 'public', entity: 'users', attribute: ['id']}*/},
            {name: 'name'/*, ref: {schema: 'public', entity: 'users', attribute: ['name']}*/},
        ])
    })
})
