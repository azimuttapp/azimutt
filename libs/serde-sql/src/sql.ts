import {Database, ParserError} from "@azimutt/database-model";
import * as chevrotain from "../src/chevrotain";
import * as generator from "./generator";
import {SqlScript} from "./statements";
import {importDatabase} from "./sqlImport";
import {exportDatabase} from "./sqlExport";

export function parseDatabase(input: string): Promise<Database> {
    return parseSql(input).then(importDatabase)
}

export function parseSql(input: string): Promise<SqlScript> {
    return parseSqlAst(input).then(chevrotain.format)
}

export function parseSqlAst(input: string): Promise<chevrotain.SqlScriptAst> {
    const {result, errors} = chevrotain.parse(input)
    if (result) {
        return Promise.resolve(result)
    } else {
        return Promise.reject((errors || []).map(importError))
    }
}

// TODO: specify SQL engine?
export function generateDatabase(database: Database): Promise<string> {
    const script: SqlScript = exportDatabase(database)
    return generateSql(script)
}

export function generateSql(script: SqlScript): Promise<string> {
    return Promise.resolve(generator.generate(script))
}

export function generateSqlAst(script: chevrotain.SqlScriptAst): Promise<string> {
    // TODO: create a generator for the AST
    return Promise.reject(new Error('Not implemented'))
}

function importError(error: chevrotain.ParserError): ParserError {
    const [lineStart, lineEnd] = error.line
    const [colStart, colEnd] = error.column
    return {
        message: error.message,
        start: {line: lineStart, column: colStart},
        end: {line: lineEnd, column: colEnd}
    }
}
