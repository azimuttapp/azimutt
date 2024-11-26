import {Database, ParserResult} from "@azimutt/models";

const amlLib = import("@azimutt/aml");
const sqlLib = import("@azimutt/parser-sql");

export async function parseAml(input: string): Promise<ParserResult<Database>> {
    return (await amlLib).parseAml(input)
}

export async function generateAml(db: Database): Promise<string> {
    return (await amlLib).generateAml(db)
}

export async function parseJson(input: string): Promise<ParserResult<Database>> {
    return (await amlLib).parseJsonDatabase(input)
}

export async function generateJson(db: Database): Promise<string> {
    return (await amlLib).generateJsonDatabase(db)
}

export async function generateDot(db: Database): Promise<string> {
    return (await amlLib).generateDot(db)
}

export async function generateMermaid(db: Database): Promise<string> {
    return (await amlLib).generateMermaid(db)
}

export async function generateMarkdown(db: Database): Promise<string> {
    return (await amlLib).generateMarkdown(db)
}

export async function parsePostgres(input: string): Promise<ParserResult<Database>> {
    return (await sqlLib).parseSql(input, 'postgres')
}

export async function generatePostgres(db: Database): Promise<string> {
    return (await sqlLib).generateSql(db, 'postgres')
}
