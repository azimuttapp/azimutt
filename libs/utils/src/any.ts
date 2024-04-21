export function getValueDeep(value: any, path: (string | number)[]): any {
    if (path.length === 0 || value === null || typeof value !== 'object') {
        return value
    } else {
        const [head, ...tail] = path
        return getValueDeep(value[head], tail)
    }
}

export function limitDepth(value: any, depth: number): any {
    if (Array.isArray(value)) {
        return depth <= 0 ? '...' : (value.length > 3 ? value.slice(0, 3).concat(['...']) : value).map(v => limitDepth(v, depth - 1))
    } else if (value === null) {
        return value
    } else if (typeof value === 'object') {
        return depth <= 0 ? '...' : Object.fromEntries(Object.entries(value).map(([key, value]) => [key, limitDepth(value, depth - 1)]))
    } else if (typeof value === 'string') {
        return value.length > 30 ? value.substring(0, 30) + '...' : value
    } else {
        return value
    }
}
