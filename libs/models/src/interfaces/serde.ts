import {Database} from "../database";
import {ParserResult} from "../parserResult";

// every serde should implement this interface
export interface Serde {
    name: string
    parse(content: string): ParserResult<Database>
    generate(db: Database): string
}
