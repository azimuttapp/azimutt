import {Database} from "../database";

// every serde should implement this interface
export interface Serde {
    name: string
    parse(content: string): Promise<Database> // should return `ParserError[]` on failure
    generate(db: Database): Promise<string>
}

export type ParserError = {
    message: string
    start?: SourcePosition
    end?: SourcePosition
}

export type SourcePosition = { line: number, column: number }
