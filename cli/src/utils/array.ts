export const groupBy = <T, K extends keyof any>(list: T[], getKey: (item: T) => K): Record<K, T[]> =>
    list.reduce((acc, item) => {
        const key = getKey(item)
        if (!acc[key]) acc[key] = []
        acc[key].push(item)
        return acc
    }, {} as Record<K, T[]>)

export const zip = <T, U>(list1: T[], list2: U[]): [T, U][] => list1.slice(0, list2.length).map((t, i) => [t, list2[i]])
