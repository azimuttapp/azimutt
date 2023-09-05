import {describe, expect, test} from "@jest/globals";
import { parseDatabaseUrl } from "@azimutt/database-types"
import {connect} from "../src/connect";
import {application, logger} from "./constants";
import {getSchema} from "../src/postgres";

// run these test with a postgres db loaded with `integration/postgres.sql` script, you can use the `integration/compose.yaml`
describe('integration', () => {
    const url = parseDatabaseUrl('postgresql://postgres:postgres@localhost:5432/azimutt_sample')

    test.skip('getSchema', async () => {
        const schema = await connect(application, url, getSchema(undefined, 10, logger))
        expect(schema.tables.length).toEqual(8)
        expect(schema.relations.length).toEqual(8)
        // polymorphic relation
        expect(schema.tables.find(t => t.table === 'events')?.columns.find(c => c.name === 'item_type')?.values).toEqual(['Category', 'Product', 'User'])
    })
})
