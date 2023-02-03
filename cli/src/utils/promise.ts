// similar to Promise.all but sequential instead of parallel, "easy" rate limiting ^^
export function sequence<T, U>(arr: T[], perform: (t: T) => Promise<U>): Promise<U[]> {
    return arr.reduce((acc, t) => {
        return acc.then(res => perform(t).then(u => res.concat([u])))
    }, Promise.resolve([]) as Promise<U[]>)
}
