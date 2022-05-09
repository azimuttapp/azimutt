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
