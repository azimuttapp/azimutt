import {ElmFlags, ElmMsg, ElmRuntime, JsMsg} from "./types/elm";

export class ElmApp {
    static init(flags: ElmFlags) {
        return new ElmApp(window.Elm.Main.init({flags}))
    }

    constructor(private app: ElmRuntime) {
    }

    send(msg: JsMsg): void {
        this.app.ports?.jsToElm.send(msg)
    }

    subscribe(callback: (msg: ElmMsg) => void): void {
        this.app.ports?.elmToJs.subscribe(msg => {
            // setTimeout: a ugly hack to wait for Elm to render the model changes before running the commands :(
            // TODO: use requestAnimationFrame instead!
            setTimeout(() => {
                callback(msg)
            }, 100)
        })
    }
}
