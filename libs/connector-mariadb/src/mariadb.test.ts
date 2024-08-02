import {describe, expect, test} from "@jest/globals";
import {ConnectorSchemaOpts, DatabaseUrlParsed, parseDatabaseUrl} from "@azimutt/models";
import {connect} from "./connect";
import {getChecks, getConstraintColumns, getSchema} from "./mariadb";
import {application, logger} from "./constants.test";

describe('mariadb', () => {
    // fake url, use a real one to test (see README for how-to)
    const url: DatabaseUrlParsed = parseDatabaseUrl('mariadb://azimutt:azimutt@localhost:3307/mariadb_sample')
    const opts: ConnectorSchemaOpts = {logger, logQueries: false, inferJsonAttributes: true, inferPolymorphicRelations: true}

    test.skip('getSchema', async () => {
        const schema = await connect(application, url, getSchema(opts), opts)
        console.log('schema', schema)
        expect(schema.entities?.length).toEqual(7)
    })
    test.skip('getConstraintColumns', async () => {
        const constraints = await connect(application, url, getConstraintColumns(opts), opts)
        console.log(`${constraints.length} constraints`, constraints)
        expect(constraints.length).toEqual(22)
    })
    test.skip('getChecks', async () => {
        const checks = await connect(application, url, getChecks(opts), opts)
        console.log(`${checks.length} checks`, checks)
        expect(checks.length).toEqual(4)
    })
})
