import {Database, Serde} from "@azimutt/database-model";
import {generateDatabase, parseDatabase} from "./sql";

export const sql: Serde = {
    name: 'SQL',
    parse: (content: string): Promise<Database> => parseDatabase(content),
    generate: (db: Database): Promise<string> => generateDatabase(db)
}

export {SqlScript, SqlStatement, Select} from "./statements";
export {generateSql, parseSql} from "./sql";
