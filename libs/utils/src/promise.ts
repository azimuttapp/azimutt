import {AnyError} from "./error";

// similar to `Promise.all` but sequential instead of parallel, "easy" rate limiting ^^
export function sequence<T, U>(arr: T[], perform: (t: T) => Promise<U>): Promise<U[]> {
    return arr.reduce((acc, t) => {
        return acc.then(res => perform(t).then(u => res.concat([u])))
    }, Promise.resolve([] as U[]))
}

// similar to `sequence` but do not fail and accumulate errors
export function sequenceSafe<T, U>(arr: T[], perform: (t: T) => Promise<U>): Promise<[[T, AnyError][], U[]]> {
    return arr.reduce((acc, t) => {
        return acc.then(([errs, res]) => perform(t)
            .then(u => [errs, res.concat([u])] as [[T, AnyError][], U[]])
            .catch(err => [errs.concat([[t, err]]), res])
        )
    }, Promise.resolve([[], []] as [[T, AnyError][], U[]]))
}

// similar to `Promise.all` but collect only successful results and do not fail, run in parallel
export function successes<T>(arr: Promise<T>[]): Promise<T[]> {
    return arr.reduce((acc, promise) => {
        return acc.then(res => promise.then(p => res.concat([p])).catch(_ => res))
    }, Promise.resolve([] as T[]))
}
