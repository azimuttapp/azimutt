export function isEmpty(v: any): boolean {
    return v === undefined
        || v === null
        || v === ''
        || (Array.isArray(v) && v.length === 0)
        || (typeof v === 'object' && Object.keys(v).length === 0)
}
