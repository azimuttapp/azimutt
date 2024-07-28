import {describe, expect, test} from "@jest/globals";
import {ConnectorSchemaOpts, DatabaseUrlParsed, parseDatabaseUrl} from "@azimutt/models";
import {connect} from "./connect";
import {getSchema} from "./oracle";
import {application, logger} from "./constants.test";

// run these test with a postgres db loaded with `integration/postgres.sql` script, you can use the `integration/compose.yaml`
describe('integration', () => {
    const url: DatabaseUrlParsed = parseDatabaseUrl('oracle:thin:system/oracle@localhost:1521')

    test.skip('getSchema', async () => {
        const opts: ConnectorSchemaOpts = {schema: undefined, sampleSize: 10, inferRelations: true, inferJsonAttributes: true, inferPolymorphicRelations: true, ignoreErrors: false, logQueries: true, logger}
        const schema = await connect(application, url, getSchema(opts), opts)
        expect(schema.entities?.length).toEqual(7)
        expect(schema.relations?.length).toEqual(7)
        // polymorphic relation
        expect(schema.entities
            ?.find((t) => t.name === 'RATINGS')?.attrs
            .find((c) => c.name === 'ITEM_KIND')?.stats?.distinctValues
        ).toEqual(['posts', 'users'])
    }, 15000)
})
