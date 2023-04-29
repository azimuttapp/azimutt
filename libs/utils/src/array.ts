// functions sorted alphabetically
export const distinct = <T>(arr: T[]): T[] => arr.filter((t, i) => arr.indexOf(t) === i)
export const groupBy = <T, K extends keyof any>(list: T[], getKey: (item: T) => K): Record<K, T[]> =>
    list.reduce((acc, item) => {
        const key = getKey(item)
        if (!acc[key]) acc[key] = []
        acc[key].push(item)
        return acc
    }, {} as Record<K, T[]>)
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
