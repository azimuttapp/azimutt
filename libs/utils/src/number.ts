// functions sorted alphabetically

export function prettyNumber(value: number): string {
    if (value === 0) return '0'
    if (value > 10) return Math.round(value).toString()
    if (value > 1) return (Math.round(value * 10) / 10).toString()
    return (Math.round(value * 100) / 100).toString()
}

export function strictParseInt(value: string): number {
    const parsedValue = parseInt(value, 10)
    if (isNaN(parsedValue) || parsedValue.toString() !== value) {
        throw new Error('Not an integer.')
    } else {
        return parsedValue
    }
}
