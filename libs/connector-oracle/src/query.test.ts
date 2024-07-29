import {describe, expect, test} from "@jest/globals";
import {ConnectorDefaultOpts, DatabaseUrlParsed, parseDatabaseUrl} from "@azimutt/models";
import {connect} from "./connect";
import {execQuery} from "./query";
import {application, logger} from "./constants.test";

describe('query', () => {
    // local url, install db or replace it to test
    const url: DatabaseUrlParsed = parseDatabaseUrl('oracle:thin:system/oracle@localhost:1521')
    const opts: ConnectorDefaultOpts = {logger, logQueries: false}

    test.skip('execQuery', async () => {
        const query = 'SELECT p.id, p.title, u.id, u.name FROM posts p JOIN users u on p.created_by = u.id FETCH FIRST 10 ROWS ONLY;'
        const results = await connect(application, url, execQuery(query, []), opts)
        expect(results.attributes).toEqual([
            {name: 'ID'/*, ref: {entity: 'POSTS', attribute: ['ID']}*/},
            {name: 'TITLE'/*, ref: {entity: 'POSTS', attribute: ['TITLE']}*/},
            {name: 'ID_1'/*, ref: {entity: 'USERS', attribute: ['ID']}*/},
            {name: 'NAME'/*, ref: {entity: 'USERS', attribute: ['NAME']}*/},
        ])
    })
    test.skip('execQuery2', async () => {
        const query = 'SELECT *\nFROM "C##AZIMUTT"."USERS"\nFETCH FIRST 100 ROWS ONLY;'
        const results = await connect(application, url, execQuery(query, []), opts)
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
