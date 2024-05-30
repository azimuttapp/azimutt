import {isEmpty} from "./validation";

// functions sorted alphabetically

export function equalDeep<T>(a: T, b: T): boolean {
    if (typeof a === 'string' || typeof a === 'number' || typeof a === 'boolean' || typeof a === 'symbol' || a === null || a === undefined) {
        return a === b
    } else if (Array.isArray(a)) {
        return Array.isArray(b) && a.length === b.length && a.every((v, i) => equalDeep(v, b[i]))
    } else if (typeof a === 'object') {
        if (typeof b === 'object' && !Array.isArray(b) && b !== null) {
            return Object.keys(a).length === Object.keys(b).length && Object.entries(a).every(([k, v]) => equalDeep(v, b[k as keyof T]))
        }
    }
    return false
}

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

// remove fields from `source` if they exist and have the same value in `ref`
export function minusFieldsDeep(source: any, ref: any): any {
    if (typeof source === 'string' || typeof source === 'number' || typeof source === 'boolean' || typeof source === 'symbol' || source === null || source === undefined) {
        return source !== ref ? source : undefined
    } else if (Array.isArray(source)) {
        if (Array.isArray(ref)) {
            const arr = source.map((v, i) => minusFieldsDeep(v, ref[i]))
            return arr.some(v => v !== undefined) ? arr : undefined
        } else {
            return source
        }
    } else if (typeof source === 'object') {
        if (typeof ref === 'object' && !Array.isArray(ref) && ref !== null) {
            const obj = Object.fromEntries(Object.entries(source).map(([key, value]) => [key, minusFieldsDeep(value, ref[key])]).filter(([, v]) => v !== undefined))
            return Object.keys(obj).length > 0 ? obj : undefined
        } else {
            return source
        }
    }
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
