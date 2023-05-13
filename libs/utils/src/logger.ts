export interface Logger {
    debug: (text: string) => void
    log: (text: string) => void
    warn: (text: string) => void
    error: (text: string) => void
}

export const console: Logger = {
    debug: (text: string) => console.debug(text),
    log: (text: string) => console.log(text),
    warn: (text: string) => console.warn(text),
    error: (text: string) => console.error(text)
}
