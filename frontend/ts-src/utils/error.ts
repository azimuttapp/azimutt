export type AnyError = any
export type StrError = string

export function formatError(err: AnyError) {
    if (err instanceof Error) {
        return err.message
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
