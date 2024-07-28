import {describe, test} from "@jest/globals";
import {
    ConnectorQueryHistoryOpts,
    DatabaseQuery,
    DatabaseUrlParsed,
    parseDatabaseUrl,
    zodParseAsync
} from "@azimutt/models";
import {connect} from "./connect";
import {getQueryHistory} from "./history";
import {application, logger} from "./constants.test";

describe('history', () => {
    // local url, install db or replace it to test
    const url: DatabaseUrlParsed = parseDatabaseUrl('oracle:thin:system/oracle@localhost:1521')
    const opts: ConnectorQueryHistoryOpts = {logger, logQueries: false, database: 'C##AZIMUTT.USERS'}

    test.skip('getQueryHistory', async () => {
        const queries: DatabaseQuery[] = await connect(application, url, getQueryHistory(opts), opts).then(zodParseAsync(DatabaseQuery.array()))
        console.log(`${queries.length} queries`, queries)
    })
})
