import {findLastIndex} from "./array"

// functions sorted alphabetically

export function indent(value: string, size: number = 2, char: string = ' ') {
    const prefix = char.repeat(size)
    return value.split('\n').map(l => prefix + l).join('\n')
}

export function joinLast(values: string[], sep: string = ', ', last: string = ' and ') {
    if (values.length === 0) {
        return ''
    } else if (values.length === 1) {
        return values[0]
    } else {
        return values.slice(0, -1).join(sep) + last + values[values.length - 1]
    }
}

export function joinLimit(values: string[], sep: string = ', ', limit: number = 5) {
    if (values.length > limit) {
        return values.slice(0, limit).join(sep) + ' ...'
    } else {
        return values.join(sep)
    }
}

export function pathJoin(...paths: string[]): string {
    const res = paths
        .flatMap(path => path.split('/'))
        .filter(part => part !== '' && part !== '.') // remove useless parts
        .filter((part, i, parts) => (part !== '..' && parts[i+1] !== '..') || (part === '..' && (parts[i-1] === '..' || parts[i-1] === undefined))) // squash parents
        .filter((part, i, parts) => (part !== '..' && parts[i+1] !== '..') || (part === '..' && (parts[i-1] === '..' || parts[i-1] === undefined))) // squash parents again (if 2 levels)
        .join('/')
    return res.startsWith('.') ? res : './' + res // add explicit relative link
}

export function pathParent(path: string): string {
    return path.split('/').slice(0, -1).join('/')
}

export function plural(word: string): string {
    if (word.endsWith('y') && !(word.endsWith('ay') || word.endsWith('ey') || word.endsWith('oy') || word.endsWith('uy'))) {
        return word.slice(0, -1) + 'ies'
    } else if (word.endsWith('s') || word.endsWith('x') || word.endsWith('z') || word.endsWith('sh') || word.endsWith('ch')) {
        return word + 'es'
    } else {
        return word + 's'
    }
}

export function pluralize(count: number, word: string): string {
    if (count === 1) {
        return `1 ${word}`
    } else {
        return `${count} ${plural(word)}`
    }
}

export function pluralizeL<T>(items: T[], word: string): string {
    return pluralize(items.length, word)
}

export function pluralizeR<K extends keyof any, V>(record: Record<K, V>, word: string): string {
    return pluralize(Object.keys(record).length, word)
}

export function removeSurroundingParentheses(value: string): string {
    if (value.startsWith('(') && value.endsWith(')')) {
        return removeSurroundingParentheses(value.slice(1, -1))
    } else {
        return value
    }
}

export function singular(word: string): string {
    if (word.endsWith('ies')) {
        return word.slice(0, -3) + 'y'
    } else if (word.endsWith('es')) {
        return word.slice(0, -2)
    } else if (word.endsWith('s')) {
        return word.slice(0, -1)
    } else {
        return word
    }
}

export function slugify(text: string, opts: {mode?: 'github'} = {}): string {
    const clean = text
        .trim()
        .toLowerCase()
        .normalize('NFKD') // split accented characters into their base characters and diacritical marks
        .replace(/[\u0300-\u036f]/g, '') // remove all the accents
    if (opts.mode === 'github') {
        return clean
            .replace(/[^a-z0-9 -]/g, '') // remove non-alphanumeric characters
            .replace(/\s/g, '-') // replace spaces with hyphens
    } else {
        return clean
            .replace(/[^a-z0-9]/g, '-') // replace other chars with '-'
            .replace(/-+/g, '-') // only keep a single '-'
            .replace(/^-+/, '') // remove leading '-'
            .replace(/-+$/, '') // remove training '-'
    }
}

export function stripIndent(value: string): string {
    const lines = value.split('\n')
    const lengths = lines.map(l => l.trim().length)
    const firstIndex = lengths.findIndex(l => l > 0)
    const lastIndex = findLastIndex(lengths, l => l > 0)
    const content = lines.slice(firstIndex, lastIndex + 1)
    const minIndent = content.reduce((acc, line) => {
        const len = line.trim().length > 0 && line.match(/^(\s*).*$/)?.[1]?.length || 0
        return acc === 0 || (0 < len && len < acc) ? len : acc
    }, 0)
    return content.map(l => l.slice(minIndent)).join('\n')
}
