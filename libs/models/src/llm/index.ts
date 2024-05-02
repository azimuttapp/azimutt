import {SqlStatement} from "../common";
import {Database, DatabaseKind} from "../database";
import {OpenAIConnector} from "./openai";
import {dbToPrompt} from "./llmUtils";

// gpt-3.5-turbo: context window: 16k tokens
// gpt-4-turbo: context window: 128k tokens

export async function textToSql(llm: OpenAIConnector, dialect: DatabaseKind, userPrompt: string, db: Database): Promise<SqlStatement> {
    const systemPrompt = 'You are a pragmatic data analyst focusing on query performance and correctness.\n' +
        `Here is the database you have at your disposal:\n${dbToPrompt(db)}\n` +
        'Answer the user request generating only a valid SQL query, no other text at all.'
    return await llm.query(systemPrompt, userPrompt)
}

export async function sqlToText(llm: OpenAIConnector, sqlQuery: SqlStatement): Promise<string> {
    // TODO: ask for name, description and explanation of the query
    const systemPrompt = 'You are an experimented data analyst.\n' +
        'The user will with you an SQL query and you will explain it how it works.\n' +
        'Answer in a clear and concise way, not extra explanation not linked to the query.'
    return await llm.query(systemPrompt, sqlQuery)
}

export async function updateSql(llm: OpenAIConnector, dialect: DatabaseKind, sqlQuery: SqlStatement, userPrompt: string, db: Database): Promise<SqlStatement> {
    // TODO: update SQL with english prompt
    return Promise.reject('Not implemented')
}

export async function fixSql(llm: OpenAIConnector, dialect: DatabaseKind, sqlQuery: SqlStatement, error: string, db: Database): Promise<SqlStatement> {
    // TODO: fix SQL query when it doesn't work
    return Promise.reject('Not implemented')
}

export async function optimizeSql(llm: OpenAIConnector, dialect: DatabaseKind, sqlQuery: SqlStatement, db: Database): Promise<SqlStatement> {
    // TODO: rewrite query for better performance, provide indexes & query plan => challenge, make it clear when not possible!
    return Promise.reject('Not implemented')
}

export async function explainQueryPlan(llm: OpenAIConnector, dialect: DatabaseKind, sqlQuery: SqlStatement, queryPlan: string): Promise<string> {
    // TODO: explain query plan
    return Promise.reject('Not implemented')
}

// TODO: chat with your db
// TODO: suggest schema improvements
// TODO: suggest schema changes for a new feature
// TODO: suggest tables for a specific topic (build layout)
// TODO: function calling to interact with Azimutt (ex: "Show all the tables related to projects")
