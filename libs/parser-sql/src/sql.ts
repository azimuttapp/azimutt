import {Database, DatabaseDiff, DatabaseKind, ParserResult} from "@azimutt/models";
import * as chevrotain from "./chevrotain";
import * as generator from "./generator";
import {SqlScript} from "./statements";
import {importDatabase} from "./sqlImport";
import {exportDatabase} from "./sqlExport";
import {parsePostgresAst} from "./postgresParser";
import {buildPostgresDatabase} from "./postgresBuilder";
import {generatePostgres, generatePostgresDiff} from "./postgresGenerator";

export function parseSql(content: string, dialect: DatabaseKind, opts: { strict?: boolean, context?: Database } = {}): ParserResult<Database> {
    const start = Date.now()
    if (dialect === DatabaseKind.enum.postgres) return parsePostgresAst(content, opts).flatMap(ast => buildPostgresDatabase(ast, start, Date.now()))
    return parseSqlScript(content).map(importDatabase)
}

export function generateSql(database: Database, dialect: DatabaseKind): string {
    if (dialect === DatabaseKind.enum.postgres) return generatePostgres(database)
    const script: SqlScript = exportDatabase(database)
    return generateSqlScript(script)
}

export function generateSqlDiff(diff: DatabaseDiff, dialect: DatabaseKind): string {
    if (dialect === DatabaseKind.enum.postgres) return generatePostgresDiff(diff)
    return `Can't generate SQL diff for ${dialect} dialect`
}

function parseSqlScript(content: string): ParserResult<SqlScript> {
    return parseSqlAst(content).map(chevrotain.format)
}

function generateSqlScript(script: SqlScript): string {
    return generator.generate(script)
}

function parseSqlAst(content: string): ParserResult<chevrotain.SqlScriptAst> {
    const {result, errors} = chevrotain.parse(content)
    if (result) {
        return ParserResult.success(result)
    } else {
        return ParserResult.failure(errors || [])
    }
}

function generateSqlAst(script: chevrotain.SqlScriptAst): Promise<string> {
    // TODO: create a generator for the AST
    return Promise.reject(new Error('Not implemented'))
}
