import {formatError} from "./error";

export function parse(value: string): any {
    try {
        console.log('Json.parse', value)
        return JSON.parse(value)
    } catch (e) {
        const v = value?.length > 20 ? value.slice(0, 20) + "..." : value
        throw `${JSON.stringify(v)} is not a valid JSON (${formatError(e)})`
    }
}
