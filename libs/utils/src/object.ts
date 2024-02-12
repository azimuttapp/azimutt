import {isEmpty} from "./any";

export function mapValues<T, U>(obj: Record<string, T>, f: (t: T) => U): Record<string, U> {
    return Object.fromEntries(Object.entries(obj).map(([k, v]) => [k, f(v)]))
}

export function filterValues<K extends keyof any, V, T extends Record<K, V>>(obj: T, p: (v: V) => boolean): T {
    return Object.fromEntries(Object.entries(obj).filter(([, v]) => p(v as V))) as T
}
export function removeUndefined<K extends keyof any, V, T extends Record<K, V>>(obj: T): T {
    return filterValues(obj, v => v !== undefined)
}

export function removeEmpty<K extends keyof any, V, T extends Record<K, V>>(obj: T): T {
    return filterValues(obj, v => !isEmpty(v))
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
