import {Database, ParserResult} from "@azimutt/models";
import * as chevrotain from "./chevrotain";
import * as generator from "./generator";
import {SqlScript} from "./statements";
import {importDatabase} from "./sqlImport";
import {exportDatabase} from "./sqlExport";

export function parseDatabase(input: string): ParserResult<Database> {
    return parseSql(input).map(importDatabase)
}

export function parseSql(input: string): ParserResult<SqlScript> {
    return parseSqlAst(input).map(chevrotain.format)
}

export function parseSqlAst(input: string): ParserResult<chevrotain.SqlScriptAst> {
    const {result, errors} = chevrotain.parse(input)
    if (result) {
        return ParserResult.success(result)
    } else {
        return ParserResult.failure(errors || [])
    }
}

// TODO: specify SQL engine?
export function generateDatabase(database: Database): string {
    const script: SqlScript = exportDatabase(database)
    return generateSql(script)
}

export function generateSql(script: SqlScript): string {
    return generator.generate(script)
}

export function generateSqlAst(script: chevrotain.SqlScriptAst): Promise<string> {
    // TODO: create a generator for the AST
    return Promise.reject(new Error('Not implemented'))
}
