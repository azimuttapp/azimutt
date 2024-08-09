import {describe, expect, test} from "@jest/globals";
import {ConnectorSchemaOpts, DatabaseUrlParsed, parseDatabaseUrl} from "@azimutt/models";
import {connect} from "./connect";
import {execQuery} from "./query";
import {application, logger} from "./constants.test";

describe('query', () => {
    // local url from [README](../README.md#local-setup), launch it or replace it to test
    const url: DatabaseUrlParsed = parseDatabaseUrl('oracle:thin:C##azimutt/azimutt@localhost:1521/FREE')
    const opts: ConnectorSchemaOpts = {logger, logQueries: false, inferJsonAttributes: true, inferPolymorphicRelations: true}

    test.skip('execQuery', async () => {
        const query = 'SELECT id, name, settings FROM users FETCH FIRST 10 ROWS ONLY;'
        const results = await connect(application, url, execQuery(query, []), opts)
        console.log('results', results)
        expect(results.rows.length).toEqual(3)
        expect(results.attributes).toEqual([
            {name: 'ID', ref: {entity: 'users', attribute: ['id']}},
            {name: 'NAME', ref: {entity: 'users', attribute: ['name']}},
            {name: 'SETTINGS', ref: {entity: 'users', attribute: ['settings']}},
        ])
    })
    test.skip('execQuery2', async () => {
        const query = 'SELECT *\nFROM "C##AZIMUTT"."USERS"\nFETCH FIRST 100 ROWS ONLY;'
        const results = await connect(application, url, execQuery(query, []), opts)
        console.log('results', results)
        expect(results.attributes).toEqual([
            {name: 'ID', ref: {schema: 'C##AZIMUTT', entity: 'USERS', attribute: ['ID']}},
            {name: 'NAME', ref: {schema: 'C##AZIMUTT', entity: 'USERS', attribute: ['NAME']}},
            {name: 'ROLE', ref: {schema: 'C##AZIMUTT', entity: 'USERS', attribute: ['ROLE']}},
            {name: 'EMAIL', ref: {schema: 'C##AZIMUTT', entity: 'USERS', attribute: ['EMAIL']}},
            {name: 'EMAIL_CONFIRMED', ref: {schema: 'C##AZIMUTT', entity: 'USERS', attribute: ['EMAIL_CONFIRMED']}},
            {name: 'SETTINGS', ref: {schema: 'C##AZIMUTT', entity: 'USERS', attribute: ['SETTINGS']}},
            {name: 'CREATED_AT', ref: {schema: 'C##AZIMUTT', entity: 'USERS', attribute: ['CREATED_AT']}},
        ])
    })
})
