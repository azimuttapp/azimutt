import {describe, expect, test} from "@jest/globals";
import {DatabaseUrlParsed, parseDatabaseUrl} from "@azimutt/database-types";
import {application} from "./constants";
import {connect} from "../src/connect";
import {execQuery} from "../src/common";

describe('query', () => {
    // local url, install db or replace it to test
    const url: DatabaseUrlParsed = parseDatabaseUrl('postgresql://postgres:postgres@localhost:5432/azimutt_dev')
    test.skip('query', async () => {
        const query = 'SELECT u.id, e.id, o.id FROM users u JOIN events e ON u.id = e.created_by JOIN organizations o on o.id = e.organization_id LIMIT 10;'
        const results = await connect(application, url, execQuery(query, []))
        expect(results.columns).toEqual([
            {name: 'id', ref: {table: 'public.users', column: 'id'}},
            {name: 'id_2', ref: {table: 'public.events', column: 'id'}},
            {name: 'id_3', ref: {table: 'public.organizations', column: 'id'}}
        ])
    })
})
