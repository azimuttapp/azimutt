import {isObject} from "./validation";

// functions sorted alphabetically

export type AnyError = any
export type StrError = string

export function errorToString(err: AnyError): string {
    if (err instanceof Error) {
        return err.message + showCause(err)
    } else if (typeof err === 'string') {
        return err
    } else if (isObject(err) && typeof err.error === 'string') {
        return err.error
    } else if (isObject(err) && typeof err.message === 'string') {
        return err.message
    } else if (isObject(err) && isObject(err.json) && typeof err.json.message === 'string') {
        return err.json.message
    } else {
        return JSON.stringify(err)
    }
}

function showCause(err: Error): string {
    if ('cause' in err && err.cause instanceof Error) {
        return `\n  cause: ${errorToString(err.cause)}`
    } else {
        return ''
    }
}
