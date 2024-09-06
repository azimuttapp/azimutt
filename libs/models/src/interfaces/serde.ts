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
    constructor(public result?: T, public errors?: ParserError[], public warnings?: ParserError[]) {
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

    public flatMap<U>(f: (t: T) => ParserResult<U>): ParserResult<U> {
        if (this.result !== undefined) {
            const res = f(this.result)
            const errors = (this.errors || []).concat(res.errors || [])
            const warnings = (this.warnings || []).concat(res.warnings || [])
            return new ParserResult<U>(res.result, errors.length > 0 ? errors : undefined, warnings.length > 0 ? warnings : undefined)
        } else {
            return new ParserResult<U>(undefined, this.errors, this.warnings)
        }
    }

    public fold<U>(onSuccess: (t: T) => U, onFailure: (e: ParserError[]) => U): U {
        return this.result !== undefined ? onSuccess(this.result) : onFailure((this.errors || []).concat(this.warnings || []))
    }
}
