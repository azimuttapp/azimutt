import * as dbml from "@dbml/core";
import DbmlDatabase from "@dbml/core/types/model_structure/database";
import {Database, ParserError} from "@azimutt/database-model";
import {importDatabase} from "./dbmlImport";
import {exportDatabase} from "./dbmlExport";
import {JsonDatabase} from "./jsonDatabase";

export function parse(content: string): Promise<Database> {
    try {
        const db: DbmlDatabase = (new dbml.Parser(undefined)).parse(content, 'dbmlv2')
        return Promise.resolve(importDatabase(db))
    } catch (e: unknown) {
        return Promise.reject(Array.isArray(e) ? importError(e as DbmlParserError[]) : e)
    }
}

export function generate(database: Database): Promise<string> {
    try {
        const json: JsonDatabase = exportDatabase(database)
        const db: DbmlDatabase = (new dbml.Parser(undefined)).parse(JSON.stringify(json), 'json')
        return Promise.resolve(dbml.ModelExporter.export(db, 'dbml', false))
    } catch (e: unknown) {
        return Promise.reject(Array.isArray(e) ? importError(e as DbmlParserError[]) : e)
    }
}

// used to make sure the generated DBML contains everything possible (comparing with `generate` function)
export function reformat(content: string): Promise<string> {
    try {
        const db: DbmlDatabase = (new dbml.Parser(undefined)).parse(content, 'dbmlv2')
        const res = dbml.ModelExporter.export(db, 'dbml', false)
        return Promise.resolve(res)
    } catch (e) {
        return Promise.reject(e)
    }
}

// not defined in `@dbml/core` :/
type DbmlParserError = {
    code: number
    message: string
    location: {
        start: {line: number, column: number}
        end: {line: number, column: number}
    }
}

function importError(errors: DbmlParserError[]): ParserError[] {
    return errors.map(e => ({
        message: e.message,
        start: {line: e.location.start.line, column: e.location.start.column},
        end: {line: e.location.end.line, column: e.location.end.column}
    }))
}
