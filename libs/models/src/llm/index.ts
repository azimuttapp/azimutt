import {z} from "zod";
import {groupBy} from "@azimutt/utils";
import {SqlStatement} from "../common";
import {AttributeName, Database, DatabaseKind, Entity, EntityId, EntityName} from "../database";
import {OpenAIConnector} from "./openai";
import {cleanJsonAnswer, cleanSqlAnswer, dbToPrompt} from "./llmUtils";

// gpt-3.5-turbo: context window: 16k tokens
// gpt-4-turbo: context window: 128k tokens
// 1 token ~ 4 chars: https://platform.openai.com/tokenizer
export {OpenAIConnector, OpenAIKey, OpenAIModel} from "./openai";

// TODO: suggest schema improvements: design, perf

export async function textToSql(llm: OpenAIConnector, dialect: DatabaseKind, userPrompt: string, db: Database): Promise<SqlStatement> {
    // https://docs.anthropic.com/en/prompt-library/sql-sorcerer
    // https://dev.to/datalynx/llms-for-text-to-sql-problems-the-benchmark-vs-real-world-performance-2064
    // if db too big (>100 tables), select relevant tables with a prompt
    // hint with tables on the current layout?
    const systemPrompt = 'You are a pragmatic data analyst focusing on query performance and correctness.\n' +
        `Here is the database you have at your disposal:\n${dbToPrompt(db)}\n` +
        `Answer the user request generating only one valid SQL query using ${dialect} dialect and formatted nicely, no other text at all, this is very important.`
    const answer = await llm.query(systemPrompt, userPrompt)
    return cleanSqlAnswer(answer)
}

export async function sqlToText(llm: OpenAIConnector, sqlQuery: SqlStatement): Promise<string> {
    // TODO: ask for name, description and explanation of the query
    const systemPrompt = 'You are an experimented data analyst.\n' +
        'The user will with you an SQL query and you will explain it how it works.\n' +
        'Answer in a clear and concise way, not extra explanation not linked to the query.'
    return await llm.query(systemPrompt, sqlQuery)
}

export async function autoLayout(llm: OpenAIConnector, entities: Entity[], userPrompt: string): Promise<EntityId[]> {
    const systemPrompt = 'You are an experienced data analyst with deep business knowledge and clever insight about data model and visualization.\n' +
        `Your goal is to help the user explore and understand the database of ${entities.length} tables.\n\n` +
        'Here are the available tables:\n' +
        '```json\n' +
        '[\n' +
        entities.map(e => JSON.stringify({schema: e.schema, table: e.name, description: e.doc}) + ',\n').join('') +
        ']\n' +
        '```\n\n' +
        'The result should be an array in the JSON format with the 30 most relevant tables with properties `schema` and `tables`, here is a format example:\n' +
        '```json\n' +
        JSON.stringify([{schema: 'public', table: 'users'}, {schema: 'analytics', table: 'events'}, {schema: 'public', table: 'credentials'}]) + '\n' +
        '```\n' +
        'Output only the JSON array, nothing else at all.\n\n' +
        'The user will prompt the topic he is investigating and looking to explore in the database:'
    const res = await llm.query(systemPrompt, userPrompt)
    const Answer = z.object({schema: z.string(), table: z.string()}).array()
    const tables = await cleanJsonAnswer(res, Answer)
    const entitiesByName = groupBy(entities, e => e.name)
    return matchEntity(tables, entitiesByName).map(t => `${t.schema}.${t.table}`)
}

export async function sqlEntities(llm: OpenAIConnector, entities: Entity[], sql: string): Promise<{id: EntityId, columns: AttributeName[]}[]> {
    const systemPrompt = 'Act as a SQL Parser. The user will give you an SQL query, and you have to extract all the schema, table and column entities.\n\n' +
        'The result should be an array in the JSON format with objects having properties: `schema`, `table` and `columns`, here is a format example:\n' +
        '```json\n' +
        JSON.stringify([{schema: 'public', table: 'users', columns: ['id', 'name', 'email']}, {schema: '', table: 'events', columns: []}]) + '\n' +
        '```\n' +
        'Output only the JSON array, nothing else at all.\n\n'
    const res = await llm.query(systemPrompt, sql)
    const Answer = z.object({schema: z.string(), table: z.string(), columns: z.string().array()}).array()
    const tables = await cleanJsonAnswer(res, Answer)
    const entitiesByName = groupBy(entities, e => e.name)
    return matchEntity(tables, entitiesByName).map(t => ({id: `${t.schema}.${t.table}`, columns: t.columns}))
}

function matchEntity<T extends {schema: string, table: string}>(tables: T[], entitiesByName: Record<EntityName, Entity[]>): T[] {
    return tables.map(t => {
        const tEntities = entitiesByName[t.table] || []
        if (tEntities.length === 0) return undefined
        const entity = tEntities.find(e => e.schema === t.schema) || tEntities[0]
        return {...t, schema: entity.schema, table: entity.name}
    }).filter(t => t !== undefined)
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
// TODO: suggest schema changes for a new feature
// TODO: function calling to interact with Azimutt (ex: "Show all the tables related to projects")
// TODO: detect PII, https://docs.anthropic.com/en/prompt-library/pii-purifier
