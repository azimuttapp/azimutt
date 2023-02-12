import {InvalidArgumentError} from "commander";

export function safeParseInt(value: string) {
    const parsedValue = parseInt(value, 10)
    if (isNaN(parsedValue) || parsedValue.toString() !== value) {
        throw new InvalidArgumentError('Not an integer.')
    } else {
        return parsedValue
    }
}
