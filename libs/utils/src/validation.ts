// functions sorted alphabetically

export function isEmpty(v: any): boolean {
    return v === undefined
        || v === null
        || v === ''
        || (Array.isArray(v) && v.length === 0)
        || (typeof v === 'object' && Object.keys(v).length === 0)
}

export const isObject = (value: unknown): value is Record<string, any> => typeof value === "object" && !Array.isArray(value) && value !== null;

export function isNotUndefined<T>(t: T | undefined): t is T {
    return t !== undefined
}
