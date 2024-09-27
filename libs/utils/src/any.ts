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

export function anyAsString(value: any): string {
    if (typeof value === 'string') return value
    if (value === undefined) return ''
    if (value === null) return 'null'
    if (typeof value === 'number') return isNaN(value) || !isFinite(value) ? 'null' : value.toString()
    if (typeof value === 'boolean') return value ? 'true' : 'false'
    if (Array.isArray(value)) return '[' + value.map(anyAsString).join(', ') + ']'
    if (value instanceof Date) return value.toISOString()
    if (value instanceof String || value instanceof Number || value instanceof Boolean) value.toString()
    if (typeof value === 'object') return '{' + Object.entries(value).map(([k, v]) => k + ': ' + anyAsString(v)).join(', ') + '}'
    return ''
}
