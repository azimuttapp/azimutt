import {describe, expect, test} from "@jest/globals";
import {ConnectorSchemaOpts, DatabaseUrlParsed, parseDatabaseUrl} from "@azimutt/models";
import {connect} from "./connect";
import {execQuery} from "./query";
import {application, logger} from "./constants.test";

describe('query', () => {
    // local url, install db or replace it to test
    const url: DatabaseUrlParsed = parseDatabaseUrl('postgresql://postgres:postgres@localhost:5432/azimutt_dev')
    const opts: ConnectorSchemaOpts = {logger, logQueries: false, inferJsonAttributes: true, inferPolymorphicRelations: true}

    test.skip('execQuery', async () => {
        const query = 'SELECT u.id, e.id, o.id FROM users u JOIN events e ON u.id = e.created_by JOIN organizations o on o.id = e.organization_id LIMIT 10;'
        const results = await connect(application, url, execQuery(query, []), opts)
        expect(results.attributes).toEqual([
            {name: 'id', ref: {schema: 'public', entity: 'users', attribute: ['id']}},
            {name: 'id_2', ref: {schema: 'public', entity: 'events', attribute: ['id']}},
            {name: 'id_3', ref: {schema: 'public', entity: 'organizations', attribute: ['id']}}
        ])
    })
})
