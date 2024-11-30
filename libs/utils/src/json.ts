// functions sorted alphabetically

export function safeJsonParse(value: string): any {
    try {
        return JSON.parse(value)
    } catch (e) {
        return value
    }
}

// same as JSON.stringify but allow flexible indentation
export function stringify(value: unknown, indent: undefined | number | string | ((p: (string | number)[], v: any) => number | string) = undefined): string {
    return stringifyInner(value, indent, [], 0)
}

function stringifyInner(value: unknown, indent: undefined | number | string | ((p: (string | number)[], v: any) => number | string), path: (string | number)[], nesting: number): string {
    if (value === null) {
        return 'null'
    } else if (typeof value === 'number') {
        return isNaN(value) || !isFinite(value) ? 'null' : value.toString()
    } else if (typeof value === 'boolean') {
        return value ? 'true' : 'false'
    } else if (typeof value === 'string' || value instanceof String) {
        return JSON.stringify(value) // 🤷 (escaping was not worth coding ^^)
    } else if (typeof value === 'bigint') {
        return value.toString()
    } else if (Array.isArray(value)) {
        const {inner, end, depth} = stringifyIndent(indent, path, value, nesting)
        const items = value.map((v, i) => {
            const asNull = v === undefined || typeof v === 'function' || typeof v === 'symbol'
            return inner + stringifyInner(asNull ? null : v, indent, [...path, i], depth)
        })
        return items.length > 0 ? '[' + items.join(!inner && typeof indent === 'function' ? ', ' : ',') + end + ']' : '[]'
    } else if (typeof value === 'object') {
        if (value instanceof Date) {
            return `"${value.toISOString()}"`
        } else if (value instanceof Number || value instanceof Boolean) {
            return value.toString()
        } else if ('toJSON' in value && typeof value.toJSON === 'function') {
            return stringifyInner(value.toJSON(), indent, path, nesting)
        } else {
            const {inner, end, depth} = stringifyIndent(indent, path, value, nesting)
            const items = Object.entries(value).filter(([, v]) => v !== undefined && typeof v !== 'function' && typeof v !== 'symbol').map(([k, v]) => {
                return inner + '"' + k + '":' + (inner || typeof indent === 'function' ? ' ' : '') + stringifyInner(v, indent, [...path, k], depth)
            })
            return items.length > 0 ? '{' + items.join(!inner && typeof indent === 'function' ? ', ' : ',') + end + '}' : '{}'
        }
    }
    return ''
}

function stringifyIndent(indent: undefined | number | string | ((p: (string | number)[], v: any) => number | string), path: (string | number)[], value: any, nesting: number): {inner: string, end: string, depth: number} {
    if (indent === undefined || indent === 0 || indent === '') {
        return {inner: '', end: '', depth: nesting}
    } else if (typeof indent === 'number') {
        return {inner: '\n' + ' '.repeat(indent * (nesting + 1)), end: '\n' + ' '.repeat(indent * nesting), depth: nesting + 1}
    } else if (typeof indent === 'string') {
        return {inner: '\n' + indent.repeat(path.length + 1), end: '\n' + indent.repeat(path.length), depth: nesting + 1}
    } else {
        return stringifyIndent(indent(path, value), path, value, nesting)
    }
}
