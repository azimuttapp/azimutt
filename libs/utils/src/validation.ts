// functions sorted alphabetically

export function isEmpty(v: any): boolean {
    return v === undefined
        || v === null
        || v === ''
        || (Array.isArray(v) && v.length === 0)
        || (typeof v === 'object' && Object.keys(v).length === 0)
}

export const isObject = (value: unknown): value is Record<string, any> => typeof value === "object" && !Array.isArray(value) && value !== null
export const isNotUndefined = <T>(t: T | undefined): t is T => t !== undefined

// this function should never be called, useful for making sure checks are exhaustive
export function isNever(p: never): any {
    throw new Error('a never param has been produced 🤯')
}
