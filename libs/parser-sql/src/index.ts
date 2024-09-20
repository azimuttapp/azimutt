import {Database, ParserResult} from "@azimutt/models";
import {generateDatabase, parseDatabase} from "./sql";

/*
  Parser:
  - https://github.com/tobymao/sqlglot: python parser, needs to be transpiled to JS (https://github.com/TranscryptOrg/Transcrypt)
  - https://github.com/taozhi8833998/node-sql-parser: parse and generate SQL, not exact but handle more syntaxes (inspired by https://github.com/florajs/sql-parser and https://github.com/alibaba/nquery)
  - https://github.com/nene/sql-parser-cst: parse and generate SQL, keep comments & formatting (forked from node-sql-parser below)
  see: https://npmtrends.com/flora-sql-parser-vs-js-sql-parser-vs-node-sql-parser-vs-node-sqlparser-vs-sql-parse-vs-sql-parser
  Formatter:
  - https://github.com/nene/prettier-plugin-sql-cst: made from sql-formatter below but not available as a lib :/
  - https://github.com/sql-formatter-org/sql-formatter
 */

export function parseSql(dialect: string, content: string, opts: { strict?: boolean, context?: Database } = {}): ParserResult<Database> {
    return parseDatabase(content)
}

export function generateSql(dialect: string, database: Database, legacy: boolean = false): string {
    return generateDatabase(database)
}
