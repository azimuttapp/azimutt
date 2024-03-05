import {findLastIndex} from "./array"

// functions sorted alphabetically

export function indent(value: string, size: number = 2, char: string = ' ') {
    const prefix = char.repeat(size)
    return value.split('\n').map(l => prefix + l).join('\n')
}

export function removeSurroundingParentheses(value: string): string {
    if (value.startsWith('(') && value.endsWith(')')) {
        return removeSurroundingParentheses(value.slice(1, -1))
    } else {
        return value
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
