export function errorToString(e: any): string {
    if (e instanceof Error) {
        return e.message
    } else if (typeof e === 'string') {
        return e
    } else {
        return JSON.stringify(e)
    }
}
