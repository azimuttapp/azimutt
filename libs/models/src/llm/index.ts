import {Database} from "../database";
import {OpenAIConnector} from "./openai";
import {dbToPrompt} from "./llmUtils";

export async function textToSql(llm: OpenAIConnector, query: string, db: Database): Promise<string> {
    const systemPrompt = 'You are a pragmatic data analyst focusing on query performance and correctness.\n' +
        `Here is the database you have at your disposal:\n${dbToPrompt(db)}\n` +
        'Answer the user request generating only a valid SQL query, no other text at all.'
    return await llm.query(systemPrompt, query)
}

export async function sqlToText(llm: OpenAIConnector, sql: string): Promise<string> {
    const systemPrompt = 'You are an experimented data analyst.\n' +
        'The user will with you an SQL query and you will explain it how it works.\n' +
        'Answer in a clear and concise way, not extra explanation not linked to the query.'
    return await llm.query(systemPrompt, sql)
}

// TODO: rewrite query for better performance
// TODO: fix SQL when it doesn't work
// TODO: explain query plan
// TODO: suggest schema changes for a new feature
// TODO: suggest schema improvements
// TODO: suggest tables for a specific topic (build layout)
