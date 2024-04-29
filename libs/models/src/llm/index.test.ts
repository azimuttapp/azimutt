import {describe, test} from "@jest/globals";
import {Database} from "../database";
import {OpenAIConnector} from "./openai";
import {sqlToText, textToSql} from "./index";
import {logger} from "../constants.test";

describe('llm', () => {
    const openai = new OpenAIConnector({
        apiKey: 'sk-proj-...',
        model: 'gpt-3.5-turbo',
        logger,
    })
    const db: Database = {entities: [
        {name: 'users', attrs: [{name: 'id', type: 'uuid'}, {name: 'name', type: 'varchar'}, {name: 'created_at', type: 'timestamp'}]}
    ]}
    test.skip('textToSql',  async () => {
        const sql = await textToSql(openai, 'Who is the oldest user?', db)
        console.log(sql)
    })
    test.skip('sqlToText',  async () => {
        const sql = await sqlToText(openai, 'SELECT * FROM users;')
        console.log(sql)
    })
})
