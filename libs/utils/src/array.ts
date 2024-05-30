import {removeEmpty} from "./object";

// functions sorted alphabetically

export const arraySame = <T>(a1: T[], a2: T[], eq: (a: T, b: T) => boolean): boolean =>
    a1.length === a2.length && a1.every((e, i) => eq(e, a2[i]))

export const collect = <T, U>(arr: T[], f: (t: T) => U | undefined): U[] => arr.map(f).filter((u): u is U => u !== undefined)

export const collectOne = <T, U>(arr: T[], f: (t: T) => U | undefined): U | undefined => {
    for (const i of arr) {
        const u = f(i)
        if (u !== undefined) {
            return u
        }
    }
    return undefined
}

export const distinct = <T>(arr: T[]): T[] => arr.filter((t, i) => arr.indexOf(t) === i)

export type Diff<T> = {left?: T[], right?: T[], both?: {left: T, right: T}[]}
export const diffBy = <T, K extends keyof any>(arr1: T[], arr2: T[], f: (t: T) => K): Diff<T> => {
    const left: T[] = []
    const both: {left: T, right: T}[] = []
    const obj2 = indexBy(arr2, f)
    arr1.forEach(a1 => {
        const k = f(a1)
        const a2 = obj2[k]
        if (a2 === undefined) {
            left.push(a1)
        } else {
            both.push({left: a1, right: a2})
        }
        delete obj2[k]
    })
    const right: T[] = arr2.filter(a2 => obj2[f(a2)] !== undefined)
    return removeEmpty({left, right, both})
}

export const findLastIndex = <T>(arr: T[], p: (t: T) => boolean): number => {
    let i = arr.length - 1
    while (i >= 0) {
        if(p(arr[i])) {
            return i
        }
        i--
    }
    return -1
}

export const groupBy = <T, K extends keyof any>(list: T[], getKey: (item: T) => K): Record<K, T[]> =>
    list.reduce((acc, item) => {
        const key = getKey(item)
        if (!acc[key]) acc[key] = []
        acc[key].push(item)
        return acc
    }, {} as Record<K, T[]>)

// similar to group by but keys must be unique so values are not a list
export const indexBy = <T, K extends keyof any>(list: T[], getKey: (item: T) => K): Record<K, T> =>
    list.reduce((acc, item) => {
        acc[getKey(item)] = item
        return acc
    }, {} as Record<K, T>)

export const maxBy = <T, V>(arr: T[], f: (t: T) => V): T | undefined => {
    let res: T | undefined = undefined
    arr.forEach(i => {
        if (res === undefined) {
            res = i
        } else if (f(res) < f(i)) {
            res = i
        }
    })
    return res
}

export const mergeBy = <T, K extends keyof any>(a1: T[], a2: T[], getKey: (i: T) => K, merge: (i1: T, i2: T) => T = (i1, i2) => ({...i1, ...i2})): T[] => {
    let others = a2.map(i2 => ({key: getKey(i2), value: i2}))
    const merged = a1.map(i1 => {
        const key = getKey(i1)
        const [toMerge, rest] = partition(others, o => o.key === key)
        others = rest
        return toMerge.reduce((acc, cur) => merge(acc, cur.value), i1)
    })
    return merged.concat(others.map(o => o.value))
}

export const minBy = <T, V>(arr: T[], f: (t: T) => V): T | undefined => {
    let res: T | undefined = undefined
    arr.forEach(i => {
        if (res === undefined) {
            res = i
        } else if (f(res) > f(i)) {
            res = i
        }
    })
    return res
}

export const partition = <T>(arr: T[], p: (t: T) => boolean): [T[], T[]] => {
    const ok = [] as T[]
    const ko = [] as T[]
    arr.forEach(i => p(i) ? ok.push(i) : ko.push(i))
    return [ok, ko]
}

export const shuffle = <T>(array: T[]): T[] => {
    // Fisher-Yates shuffle
    const arr = [...array] // shallow copy of array to avoid in-place updates
    let count = arr.length
    let rand
    let temp
    while (count) {
        rand = Math.random() * count-- | 0
        temp = arr[count]
        arr[count] = arr[rand]
        arr[rand] = temp
    }
    return arr
}

export const zip = <T, U>(list1: T[], list2: U[]): [T, U][] => list1.slice(0, list2.length).map((t, i) => [t, list2[i]])
