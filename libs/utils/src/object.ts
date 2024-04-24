import {isEmpty} from "./validation";

// functions sorted alphabetically

export function filterValues<K extends keyof any, V, T extends Record<K, V>>(obj: T, p: (v: V) => boolean): T {
    return Object.fromEntries(Object.entries(obj).filter(([, v]) => p(v as V))) as T
}

export function mapEntries<T, U>(obj: Record<string, T>, f: (k: string, v: T) => U): Record<string, U> {
    return Object.fromEntries(Object.entries(obj).map(([k, v]) => [k, f(k, v)]))
}

export function mapValues<T, U>(obj: Record<string, T>, f: (t: T) => U): Record<string, U> {
    return mapEntries(obj, (_, v) => f(v))
}

export function mapEntriesAsync<T, U>(obj: Record<string, T>, f: (k: string, v: T) => Promise<U>): Promise<Record<string, U>> {
    return Promise.all(Object.entries(obj).map(([k, v]) => f(k, v).then(u => [k, u]))).then(Object.fromEntries)
}

export function mapValuesAsync<T, U>(obj: Record<string, T>, f: (t: T) => Promise<U>): Promise<Record<string, U>> {
    return mapEntriesAsync(obj, (_, v) => f(v))
}

export function removeEmpty<K extends keyof any, V, T extends Record<K, V>>(obj: T): T {
    return filterValues(obj, v => !isEmpty(v))
}

export function removeFieldsDeep(obj: any, keysToRemove: string[]): any {
    if (Array.isArray(obj)) {
        return obj.map(item => removeFieldsDeep(item, keysToRemove))
    }

    if (typeof obj === 'object' && obj !== null) {
        const res: { [key: string]: any } = {}
        Object.keys(obj).forEach((key) => {
            if (keysToRemove.indexOf(key) < 0) {
                res[key] = removeFieldsDeep(obj[key], keysToRemove)
            }
        })
        return res
    }

    return obj
}

export function removeUndefined<K extends keyof any, V, T extends Record<K, V>>(obj: T): T {
    return filterValues(obj, v => v !== undefined)
}
