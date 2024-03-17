import {findLastIndex} from "./array"

// functions sorted alphabetically

export function indent(value: string, size: number = 2, char: string = ' ') {
    const prefix = char.repeat(size)
    return value.split('\n').map(l => prefix + l).join('\n')
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

export function removeSurroundingParentheses(value: string): string {
    if (value.startsWith('(') && value.endsWith(')')) {
        return removeSurroundingParentheses(value.slice(1, -1))
    } else {
        return value
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
