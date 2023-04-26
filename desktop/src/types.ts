export type Versions = {
    node: () => string
    chrome: () => string
    electron: () => string
    ping: () => Promise<string>
}
