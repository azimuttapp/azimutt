import {findLastIndex} from "./array"
import {isNotUndefined} from "./validation";

// functions sorted alphabetically

export function indent(value: string, size: number = 2, char: string = ' ') {
    const prefix = char.repeat(size)
    return value.split('\n').map(l => prefix + l).join('\n')
}

export const isCamelUpper = (value: string): boolean => !!value.match(/^([A-Z][a-z0-9]*)+$/)
export const isCamelLower = (value: string): boolean => !!value.match(/^([a-z][a-z0-9]*)([A-Z][a-z0-9]*)*$/)
export const isSnakeUpper = (value: string): boolean => !!value.match(/^([A-Z][A-Z0-9]*)(_[A-Z0-9]*)*$/)
export const isSnakeLower = (value: string): boolean => !!value.match(/^([a-z][a-z0-9]*)(_[a-z0-9]*)*$/)
export const isKebabUpper = (value: string): boolean => !!value.match(/^([A-Z][A-Z0-9]*)(-[A-Z0-9]*)*$/)
export const isKebabLower = (value: string): boolean => !!value.match(/^([a-z][a-z0-9]*)(-[a-z0-9]*)*$/)

export type StringCase = 'camel-upper' | 'camel-lower' | 'snake-upper' | 'snake-lower' | 'kebab-upper' | 'kebab-lower'

export const compatibleCases = (value: string): StringCase[] => [
    isCamelUpper(value) ? 'camel-upper' as const : undefined,
    isCamelLower(value) ? 'camel-lower' as const : undefined,
    isSnakeUpper(value) ? 'snake-upper' as const : undefined,
    isSnakeLower(value) ? 'snake-lower' as const : undefined,
    isKebabUpper(value) ? 'kebab-upper' as const : undefined,
    isKebabLower(value) ? 'kebab-lower' as const : undefined,
].filter(isNotUndefined)

export function joinLast(values: string[], sep: string = ', ', last: string = ' and '): string {
    if (values.length === 0) {
        return ''
    } else if (values.length === 1) {
        return values[0]
    } else {
        return values.slice(0, -1).join(sep) + last + values[values.length - 1]
    }
}

export function joinLimit(values: string[], sep: string = ', ', limit: number = 5): string {
    if (values.length > limit) {
        return values.slice(0, limit).join(sep) + ' ...'
    } else {
        return values.join(sep)
    }
}

export function maxLen(value: string, max: number): string {
    if (value.length > max) {
        return value.slice(0, max - 3) + '...'
    } else {
        return value
    }
}

export function pathJoin(...paths: string[]): string {
    const res = paths
        .flatMap(path => path.split('/'))
        .filter(part => part !== '' && part !== '.') // remove useless parts
        .filter((part, i, parts) => (part !== '..' && parts[i+1] !== '..') || (part === '..' && (parts[i-1] === '..' || parts[i-1] === undefined))) // squash parents
        .filter((part, i, parts) => (part !== '..' && parts[i+1] !== '..') || (part === '..' && (parts[i-1] === '..' || parts[i-1] === undefined))) // squash parents again (if 2 levels)
        .join('/')
    return res.startsWith('.') || res.startsWith('~') ? res : './' + res // add explicit relative link
}

export function pathParent(path: string): string {
    return pathJoin(...path.split('/').filter(p => !!p).slice(0, -1))
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
    } else if (word.endsWith('ses') || word.endsWith('xes') || word.endsWith('zes') || word.endsWith('hes')) {
        return word.slice(0, -2)
    } else if (word.endsWith('s')) {
        return word.slice(0, -1)
    } else {
        return word
    }
}

export function cleanText(text: string): string {
    return text
        .trim()
        .toLowerCase()
        .normalize('NFKD') // split accented characters into their base characters and diacritical marks
        .replace(/[\u0300-\u036f]/g, '') // remove all the accents
}

export function slugify(text: string): string {
    return cleanText(text)
        .replace(/[^a-z0-9]/g, '-') // replace other chars with '-'
        .replace(/-+/g, '-') // only keep a single '-'
        .replace(/^-+/, '') // remove leading '-'
        .replace(/-+$/, '') // remove training '-'
}

export function slugifyGitHub(text: string): string {
    return cleanText(text)
        .replace(/[^a-z0-9 -]/g, '') // remove non-alphanumeric characters
        .replace(/\s/g, '-') // replace spaces with hyphens
}

export function splitWords(text: string): string[] {
    const {word, words} = Array.from(text).reduce(({word, words}, cur) => {
        const code = cur.charCodeAt(0)
        if (isLowerChar(code) || isNumber(code)) {
            return {word: word + cur, words: words}
        } else if (isUpperChar(code)) {
            const len = word.length
            if (len === 0 || isUpperChar(word.charCodeAt(len - 1))) {
                return {word: word + cur, words: words}
            } else {
                return {word: cur, words: word ? words.concat([word]) : words}
            }
        } else {
            return {word: '', words: word ? words.concat([word]) : words}
        }
    }, {word: '', words: []} as { word: string, words: string[] })
    return words.concat([word]).filter(w => !!w).map(w => w.toLowerCase())
}

// avoid regex for better perf
const isLowerChar = (code: number): boolean => 97 <= code && code <= 122
const isUpperChar = (code: number): boolean => 65 <= code && code <= 90
const isNumber = (code: number): boolean => 48 <= code && code <= 57

export function stripIndent(value: string): string {
    const lines = value.split('\n')
    const lengths = lines.map(l => l.trim().length)
    const firstIndex = lengths.findIndex(l => l > 0)
    const lastIndex = findLastIndex(lengths, l => l > 0)
    const content = lines.slice(firstIndex, lastIndex + 1)
    const minIndent = content.reduce((acc, line) => {
        const len = line.trim().length > 0 && line.match(/^(\s*).*$/)?.[1]?.length || 0
        return acc === undefined || (0 < len && len < acc) ? len : acc
    }, undefined as number | undefined)
    return content.map(l => l.slice(minIndent)).join('\n')
}
