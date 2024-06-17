import {describe, test} from "@jest/globals";
import * as fs from "node:fs";
import {Database, DatabaseKind} from "../database";
import {sqlToText, textToSql} from "./index";
import {OpenAIConnector} from "./openai";

describe('llm', () => {
    const openai = new OpenAIConnector({
        apiKey: 'sk-proj-...',
        model: 'gpt-3.5-turbo',
    })
    const smallDb: Database = {entities: [
        {name: 'users', attrs: [{name: 'id', type: 'uuid'}, {name: 'name', type: 'varchar'}, {name: 'created_at', type: 'timestamp'}]}
    ]}
    const azimuttDb = JSON.parse(fs.readFileSync('resources/azimutt.json').toString())
    const metabaseDb = JSON.parse(fs.readFileSync('resources/metabase.json').toString())
    test.skip('textToSql',  async () => {
        const sql = await textToSql(openai, DatabaseKind.enum.postgres, 'Who is the oldest user?', smallDb)
        console.log(sql)
    })
    test.skip('sqlToText',  async () => {
        const sql = await sqlToText(openai, 'SELECT * FROM users;')
        console.log(sql)
    })
})
