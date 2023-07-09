import {AzimuttSchema, Parser} from "@azimutt/database-types";
import {parseCommand, SqlCommand} from "./command";

const parser: Parser = {
    name: 'SQL',
    parse: (content: string): Promise<AzimuttSchema> => Promise.reject('Not implemented: sql.parse')
}
export const sql = {
    ...parser,
    parseCommand: (sql: string): SqlCommand => parseCommand(sql)
}
