export function mapValues<T, U>(obj: Record<string, T>, f: (t: T) => U): Record<string, U> {
    return Object.fromEntries(Object.entries(obj).map(([k, v]) => [k, f(v)]))
}

export function filterKeys<T>(obj: Record<string, T>, p: (k: string) => boolean): Record<string, T> {
    return Object.fromEntries(Object.entries(obj).filter(([k]) => p(k)))
}

export function filterValues<T>(obj: Record<string, T>, p: (v: T) => boolean): Record<string, T> {
    return Object.fromEntries(Object.entries(obj).filter(([, v]) => p(v)))
}

export function omit<T>(obj: { [key: string]: T }, keys: string[]): { [key: string]: T } {
    return filterKeys(obj, key => !keys.includes(key))
}

export function removeUndefined<K extends keyof any, V, T extends Record<K, V>>(obj: T): T {
    return filterValues(obj, v => v !== undefined) as T
}

export function deeplyRemoveFields(obj: any, keysToRemove: string[]): any {
    if (Array.isArray(obj)) {
        return obj.map(item => deeplyRemoveFields(item, keysToRemove))
    }

    if (typeof obj === 'object' && obj !== null) {
        const res: { [key: string]: any } = {}
        Object.keys(obj).forEach((key) => {
            if (keysToRemove.indexOf(key) < 0) {
                res[key] = deeplyRemoveFields(obj[key], keysToRemove)
            }
        })
        return res
    }

    return obj
}
