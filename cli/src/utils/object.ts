export function mapValues<T, U>(obj: Record<string, T>, f: (v: T) => U): Record<string, U> {
    return Object.fromEntries(Object.entries(obj).map(([k, v]) => [k, f(v)]))
}

export function filterValues<T>(obj: Record<string, T>, p: (v: T) => boolean): Record<string, T> {
    return Object.fromEntries(Object.entries(obj).filter(([, v]) => p(v)))
}
