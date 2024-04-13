import {Database, ParserResult, Serde} from "@azimutt/models";
import {generateDatabase, parseDatabase} from "./sql";

export const sql: Serde = {
    name: 'SQL',
    parse: (content: string): ParserResult<Database> => parseDatabase(content),
    generate: (db: Database): string => generateDatabase(db)
}

export {SqlScript, SqlStatement, Select} from "./statements";
export {generateSql, parseSql} from "./sql";
