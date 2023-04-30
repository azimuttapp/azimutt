export type AnyError = any
export type StrError = string

export function errorToString(err: AnyError): string {
    if (err instanceof Error) {
        return err.message + showCause(err)
    } else if (typeof err === 'string') {
        return err
    } else if (typeof err === 'object' && err.json && typeof err.json.message === 'string') {
        return err.json.message
    } else if (typeof err === 'object' && err && typeof err.statusCode === 'number' && typeof err.message === 'string') {
        return err.message
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
