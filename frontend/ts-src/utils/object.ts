export const mapValues = <T, U>(obj: Record<string, T>, f: (t: T) => U): Record<string, U> =>
    Object.keys(obj).reduce((acc, k) => {
        acc[k] = f(obj[k])
        return acc
    }, {} as Record<string, U>)
