export type AnyError = any
export type StrError = string

export function formatError(err: AnyError) {
    if (err instanceof Error) {
        return err.message
    } else if (typeof err === 'string') {
        return err
    } else if (typeof err === 'object' && err.json && typeof err.json.message === 'string') {
        return err.json.message
    } else {
        return JSON.stringify(err)
    }
}
