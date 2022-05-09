export function loadScript(url: string) {
    return new Promise((resolve, reject) => {
        const script = document.createElement('script')
        script.src = url
        script.type='text/javascript'
        script.addEventListener('load', resolve)
        script.addEventListener('error', reject)
        document.getElementsByTagName('head')[0].appendChild(script)
    })
}
