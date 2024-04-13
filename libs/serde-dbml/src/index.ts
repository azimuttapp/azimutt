import {Database, ParserResult, Serde} from "@azimutt/models";
import {generate, parse} from "./dbml";

export const dbml: Serde = {
    name: 'DBML',
    parse: (content: string): ParserResult<Database> => parse(content),
    generate: (db: Database): string => generate(db)
}
