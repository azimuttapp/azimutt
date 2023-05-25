export interface Logger {
    debug: (text: string) => void
    log: (text: string) => void
    warn: (text: string) => void
    error: (text: string) => void
}
