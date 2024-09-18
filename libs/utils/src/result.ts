export abstract class Result<A, E> {
    public static success<B, F = any>(result: B): Result<B, F> {
        return new ResultSuccess<B, F>(result)
    }

    public static failure<F, B = any>(error: F): Result<B, F> {
        return new ResultFailure<B, F>(error)
    }

    abstract getOrThrow(): A
    abstract getOrNull(): A | null
    abstract getOrUndefined(): A | undefined
    abstract errOrNull(): E | null
    abstract swap(): Result<E, A>
    abstract map<B>(f: (a: A) => B): Result<B, E>
    abstract mapError<F>(f: (e: E) => F): Result<A, F>
    abstract flatMap<B>(f: (a: A) => Result<B, E>): Result<B, E>
    abstract fold<B>(onSuccess: (a: A) => B, onFailure: (e: E) => B): B
    abstract toPromise(): Promise<A>
    abstract toJson(): {success?: A, failure?: E}
}

class ResultSuccess<A, E> extends Result<A, E> {
    constructor(public readonly value: A) {
        super()
        Object.freeze(this)
    }

    public getOrThrow(): A {
        return this.value
    }

    public getOrNull(): A | null {
        return this.value
    }

    public getOrUndefined(): A | undefined {
        return this.value
    }

    public errOrNull(): E | null {
        return null
    }

    public swap(): Result<E, A> {
        return new ResultFailure<E, A>(this.value)
    }

    public map<B>(f: (a: A) => B): Result<B, E> {
        return new ResultSuccess(f(this.value))
    }

    public mapError<F>(f: (e: E) => F): Result<A, F> {
        return new ResultSuccess<A, F>(this.value)
    }

    public flatMap<B>(f: (a: A) => Result<B, E>): Result<B, E> {
        return f(this.value)
    }

    public fold<B>(onSuccess: (a: A) => B, onFailure: (e: E) => B): B {
        return onSuccess(this.value)
    }

    public toPromise(): Promise<A> {
        return Promise.resolve(this.value)
    }

    public toJson(): {success?: A, failure?: E} {
        return {success: this.value}
    }
}

class ResultFailure<A, E> extends Result<A, E> {
    constructor(public readonly error: E) {
        super()
        Object.freeze(this)
    }

    public getOrThrow(): A {
        throw this.error
    }

    public getOrNull(): A | null {
        return null
    }

    public getOrUndefined(): A | undefined {
        return undefined
    }

    public errOrNull(): E | null {
        return this.error
    }

    public swap(): Result<E, A> {
        return new ResultSuccess<E, A>(this.error)
    }

    public map<B>(f: (a: A) => B): Result<B, E> {
        return new ResultFailure<B, E>(this.error)
    }

    public mapError<F>(f: (e: E) => F): Result<A, F> {
        return new ResultFailure<A, F>(f(this.error))
    }

    public flatMap<B>(f: (a: A) => Result<B, E>): Result<B, E> {
        return new ResultFailure<B, E>(this.error)
    }

    public fold<B>(onSuccess: (a: A) => B, onFailure: (e: E) => B): B {
        return onFailure(this.error)
    }

    public toPromise(): Promise<A> {
        return Promise.reject(this.error)
    }

    public toJson(): {success?: A, failure?: E} {
        return {failure: this.error}
    }
}
