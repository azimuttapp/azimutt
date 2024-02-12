import {filterValues} from "@azimutt/utils";

// TODO: move to @azimutt/utils

export function removeEmpty<K extends keyof any, V, T extends Record<K, V>>(obj: T): T {
    return filterValues(obj, v => !isEmpty(v)) as T
}

export function isEmpty(v: any): boolean {
    return v === undefined || v === null || v === ''
        || (Array.isArray(v) && v.length === 0)
        || (typeof v === 'object' && Object.keys(v).length === 0)
}
