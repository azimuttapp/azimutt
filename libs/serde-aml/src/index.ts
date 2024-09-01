import {Database, ParserResult, Serde} from "@azimutt/models";
import {generateAml, parseAml} from "./aml";

export const aml: Serde = {
    name: 'AML',
    parse: (content: string): ParserResult<Database> => parseAml(content),
    generate: (db: Database): string => generateAml(db)
}
