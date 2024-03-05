// functions sorted alphabetically

export function strictParseInt(value: string): number {
    const parsedValue = parseInt(value, 10)
    if (isNaN(parsedValue) || parsedValue.toString() !== value) {
        throw new Error('Not an integer.')
    } else {
        return parsedValue
    }
}
