import {Database, DatabaseKind, ParserResult} from "@azimutt/models";
import * as chevrotain from "./chevrotain";
import * as generator from "./generator";
import {SqlScript} from "./statements";
import {importDatabase} from "./sqlImport";
import {exportDatabase} from "./sqlExport";

export function parseSql(content: string, dialect: DatabaseKind, opts: { strict?: boolean, context?: Database } = {}): ParserResult<Database> {
    return parseSqlScript(content).map(importDatabase)
}

export function generateSql(database: Database, dialect: DatabaseKind): string {
    const script: SqlScript = exportDatabase(database)
    return generateSqlScript(script)
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
