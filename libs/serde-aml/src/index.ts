import {Database, ParserResult, Serde} from "@azimutt/models";
import {generate, parse} from "./aml";

export const dbml: Serde = {
    name: 'AML',
    parse: (content: string): ParserResult<Database> => parse(content),
    generate: (db: Database): string => generate(db)
}
