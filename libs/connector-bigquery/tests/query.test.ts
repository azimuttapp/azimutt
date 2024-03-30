import {describe, test} from "@jest/globals";
import {DatabaseUrlParsed, parseDatabaseUrl} from "@azimutt/database-model";
import {connect} from "../src/connect";
import {application, logger} from "./constants";
import {execQuery} from "../src/query";

describe('query', () => {
    // fake url, use a real one to test (see README for how-to)
    const url: DatabaseUrlParsed = parseDatabaseUrl('bigquery://bigquery.googleapis.com/azimutt-experiments?key=local/key.json')
    test.skip('query', async () => {
        const query = 'SELECT * FROM azimutt_connector_trial.azimutt_biggest_users WHERE string_field_0 = ? LIMIT 10;'
        const params = ['HumanTalks Paris orga']
        const results = await connect(application, url, execQuery(query, params), {logger, logQueries: true})
        console.log('results', results)
    })
})
