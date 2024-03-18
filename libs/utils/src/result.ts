export class Result<E, T> {
    private constructor(public result?: T, public error?: E) {
        Object.freeze(this)
    }

    public static success<U>(result: U): Result<any, U> {
        return new Result<any, U>(result, undefined)
    }

    public static failure<U>(error: U): Result<U, any> {
        return new Result<U, any>(undefined, error)
    }

    public map<U>(f: (t: T) => U): Result<E, U> {
        return this.result !== undefined ? new Result<E, U>(f(this.result), undefined) : new Result<E, U>(undefined, this.error)
    }

    public flatMap<U>(f: (t: T) => Result<E, U>): Result<E, U> {
        return this.result !== undefined ? f(this.result) : new Result<E, U>(undefined, this.error)
    }
}
