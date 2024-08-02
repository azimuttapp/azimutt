import {describe, expect, test} from "@jest/globals";
import {ConnectorSchemaOpts, DatabaseUrlParsed, parseDatabaseUrl} from "@azimutt/models";
import {connect} from "./connect";
import {execQuery} from "./query";
import {getColumns, getConstraintColumns, getSchema, getTables} from "./mysql";
import {application, logger} from "./constants.test";

describe('mysql', () => {
    // fake url, use a real one to test (see README for how-to)
    const url: DatabaseUrlParsed = parseDatabaseUrl('mysql://azimutt:azimutt@localhost:3306/mysql_sample')
    const opts: ConnectorSchemaOpts = {logger, logQueries: false, inferJsonAttributes: true, inferPolymorphicRelations: true}

    test.skip('execQuery', async () => {
        const results = await connect(application, url, execQuery("SELECT name, slug FROM users WHERE slug = ?;", ['ghost']), opts)
        console.log('results', results)
        expect(results.rows.length).toEqual(1)
    })
    test.skip('getSchema', async () => {
        const schema = await connect(application, url, getSchema(opts), opts)
        console.log('schema', schema)
        expect(schema.entities?.length).toEqual(7)
    })
    test.skip('getTables', async () => {
        const tables = await connect(application, url, getTables(opts), opts)
        console.log(`${tables.length} tables`, tables)
        expect(tables.length).toEqual(7)
    })
    test.skip('getColumns', async () => {
        const columns = await connect(application, url, getColumns(opts), opts)
        console.log(`${columns.length} columns`, columns)
        expect(columns.length).toEqual(124)
    })
    test.skip('getConstraintColumns', async () => {
        const constraints = await connect(application, url, getConstraintColumns(opts), opts)
        console.log(`${constraints.length} constraints`, constraints)
        expect(constraints.length).toEqual(64)
    })
})
