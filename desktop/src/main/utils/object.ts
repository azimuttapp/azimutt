export function filterValues<T>(obj: Record<string, T>, p: (v: T) => boolean): Record<string, T> {
    return Object.fromEntries(Object.entries(obj).filter(([, v]) => p(v)))
}
