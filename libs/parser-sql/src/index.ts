import {DatabaseSchema as schemaJsonDatabase, generateJsonDatabase, parseJsonDatabase} from "@azimutt/models";
import packageJson from "../package.json";
import {generateSql, generateSqlDiff, parseSql} from "./sql";

const monaco = {}
const version = packageJson.version

// make it available locally: `npm run build:browser && cp out/bundle.min.js ../../backend/priv/static/elm/sql.min.js && cp out/bundle.min.js.map ../../backend/priv/static/elm/sql.min.js.map`
// update `backend/lib/azimutt_web/templates/website/_editors-script.html.heex` to use local files
export * from "@azimutt/models"
export {parseSql, generateSql, generateSqlDiff, parseJsonDatabase, generateJsonDatabase, schemaJsonDatabase, monaco, version}

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
