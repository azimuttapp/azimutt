import {describe, expect, test} from "@jest/globals";
import {ConnectorSchemaOpts, DatabaseUrlParsed, parseDatabaseUrl} from "@azimutt/models";
import {connect} from "./connect";
import {execQuery} from "./query";
import {application, logger} from "./constants.test";

describe('query', () => {
    // local url from [README](../README.md#local-setup), launch it or replace it to test
    const url: DatabaseUrlParsed = parseDatabaseUrl('mongodb://localhost:27017/mongo_sample')
    const opts: ConnectorSchemaOpts = {logger, logQueries: false, database: url.db, inferJsonAttributes: true, inferPolymorphicRelations: true}

    test.skip('execQuery', async () => {
        const results = await connect(application, url, execQuery('db.users.find({"id": 1});', []), opts)
        console.log('results', results)
        expect(results.rows.length).toEqual(1)
    })
    test.skip('execQuery2', async () => {
        const results = await connect(application, url, execQuery('db.users.aggregate([{"$sortByCount":"$role"},{"$project":{"_id":0,"role":"$_id","count":"$count"}}]).limit(100);', []), opts)
        console.log('results', results)
        expect(results.rows.length).toEqual(2)
    })
})
