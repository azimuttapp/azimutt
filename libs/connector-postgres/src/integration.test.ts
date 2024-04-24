import {describe, expect, test} from "@jest/globals";
import {parseDatabaseUrl, ConnectorSchemaOpts} from "@azimutt/models";
import {connect} from "./connect";
import {getSchema} from "./postgres";
import {application, logger} from "./constants.test";

// run these test with a postgres db loaded with `integration/postgres.sql` script, you can use the `integration/compose.yaml`
describe('integration', () => {
    const url = parseDatabaseUrl('postgresql://postgres:postgres@localhost:5432/azimutt_sample')

    test.skip('getSchema', async () => {
        const schemaOpts: ConnectorSchemaOpts = {schema: undefined, sampleSize: 10, inferRelations: true, ignoreErrors: false, logQueries: true, logger}
        const schema = await connect(application, url, getSchema(schemaOpts), {logger, logQueries: true})
        expect(schema.entities?.length).toEqual(8)
        expect(schema.relations?.length).toEqual(8)
        // polymorphic relation
        expect(schema.entities?.find(t => t.name === 'events')?.attrs.find(c => c.name === 'item_type')?.stats?.distinctValues).toEqual(['Category', 'Product', 'User'])
    })
})
