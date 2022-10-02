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

    // https://stackoverflow.com/questions/105034/how-to-create-a-guid-uuid/2117523#2117523
    if (!crypto.randomUUID) {
        crypto.randomUUID = function () {
            // @ts-expect-error
            return ([1e7]+-1e3+-4e3+-8e3+-1e11).replace(/[018]/g, c => (c ^ crypto.getRandomValues(new Uint8Array(1))[0] & 15 >> c / 4).toString(16))
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
