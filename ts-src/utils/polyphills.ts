export function loadPolyfills() {
    // https://developer.mozilla.org/fr/docs/Web/JavaScript/Reference/Global_Objects/String/includes
    if (!String.prototype.includes) {
        String.prototype.includes = function (search: string | RegExp, start) {
            if (search instanceof RegExp) {
                throw TypeError('first argument must not be a RegExp')
            }
            if (start === undefined) {
                start = 0
            }
            return this.indexOf(search, start) !== -1
        }
    }

    // empower Elm for time measurements (inspired from https://ellie-app.com/g7kpM8n9Z6Ka1)
    const consoleLog = console.log
    console.log = (...args) => {
        const msg = args[0]
        if (typeof msg === 'string' && msg.startsWith('[elm-time')) {
            if (msg.startsWith('[elm-time-end]')) {
                console.timeEnd(msg.slice(15, -4))
            } else {
                console.time(msg.slice(11, -4))
            }
        } else {
            consoleLog(...args)
        }
    }
}