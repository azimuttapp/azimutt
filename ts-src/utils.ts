import {Env} from "./types/basics";

export function loadScript(url: string): Promise<Event> {
    return new Promise<Event>((resolve, reject) => {
        const script = document.createElement('script')
        script.src = url
        script.type = 'text/javascript'
        script.addEventListener('load', resolve)
        script.addEventListener('error', reject)
        document.getElementsByTagName('head')[0].appendChild(script)
    })
}

export function getEnv(): Env {
    return window.location.hostname === 'localhost' ? 'dev' :
        window.location.hostname === 'azimutt.app' ? 'prod' :
            'staging'
}

export function randomUID() {
    return window.uuidv4()
}
