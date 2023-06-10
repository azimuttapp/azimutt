export function removeSurroundingParentheses(value: string): string {
    if (value.startsWith('(') && value.endsWith(')')) {
        return removeSurroundingParentheses(value.slice(1, -1))
    } else {
        return value
    }
}
