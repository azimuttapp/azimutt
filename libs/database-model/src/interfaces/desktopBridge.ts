import {Connector} from "./connector";

export type DesktopBridge = Connector & {
    versions: {
        node: () => string
        chrome: () => string
        electron: () => string
    }
    ping: () => Promise<string>
}
