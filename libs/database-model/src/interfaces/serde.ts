import {Database} from "../database";

// every serde should implement this interface
export interface Serde {
    name: string
    parse(content: string): ParserResult<Database>
    generate(db: Database): string
}

export type ParserPosition = [number, number] // [start, end]
export type ParserError = {
    name: string,
    message: string,
    position?: { offset: ParserPosition, line: ParserPosition, column: ParserPosition }
}

export class ParserResult<T> {
    private constructor(public result?: T, public errors?: ParserError[], public warnings?: ParserError[]) {
        Object.freeze(this)
    }

    public static success<U>(result: U): ParserResult<U> {
        return new ParserResult<U>(result)
    }

    public static failure<U>(errors: ParserError[], warnings?: ParserError[]): ParserResult<U> {
        return new ParserResult<U>(undefined, errors, warnings)
    }

    public map<U>(f: (t: T) => U): ParserResult<U> {
        return new ParserResult<U>(this.result !== undefined ? f(this.result) : undefined, this.errors, this.warnings)
    }
}
