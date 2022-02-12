window.addEventListener('load', function() {
    const isDev = window.location.hostname === 'localhost'
    const isProd = window.location.hostname === 'azimutt.app'
    const skipAnalytics = !!JSON.parse(localStorage.getItem('skip-analytics'))
    const analytics = initAnalytics(isProd && !skipAnalytics)
    const errorTracking = initErrorTracking(isProd)
    const flags = {now: Date.now()}
    const app = Elm.Main.init({flags})


    /* PWA service worker */

    if ('serviceWorker' in navigator && isProd) {
        navigator.serviceWorker.register("/service-worker.js")
            // .then(reg => console.log('service-worker registered!', reg))
            // .catch(err => console.log('service-worker failed to register!', err))
    }


    /* Elm ports */

    function sendToElm(msg) {
        // console.log('js message', msg)
        app.ports.jsToElm.send(msg)
    }
    app.ports && app.ports.elmToJs.subscribe(port => {
        // setTimeout: a ugly hack to wait for Elm to render the model changes before running the commands :(
        setTimeout(() => {
            // console.log('elm message', msg)
            switch (port.kind) {
                case 'Click':           click(port.id); break;
                case 'MouseDown':       mousedown(port.id); break;
                case 'Focus':           focus(port.id); break;
                case 'Blur':            blur(port.id); break;
                case 'ScrollTo':        scrollTo(port.id, port.position); break;
                case 'SetClasses':      setClasses(port.html, port.body); break;
                case 'AutofocusWithin': autofocusWithin(port.id); break;
                case 'LoadProjects':    loadProjects(); break;
                case 'SaveProject':     saveProject(port.project); break;
                case 'DropProject':     dropProject(port.project); break;
                case 'GetLocalFile':    getLocalFile(port.project, port.source, port.file); break;
                case 'GetRemoteFile':   getRemoteFile(port.project, port.source, port.url, port.sample); break;
                case 'GetSourceId':     getSourceId(port.src, port.ref); break;
                case 'ObserveSizes':    observeSizes(port.ids); break;
                case 'ListenKeys':      listenHotkeys(port.keys); break;
                case 'TrackPage':       analytics.then(a => a.trackPage(port.name)); break;
                case 'TrackEvent':      analytics.then(a => a.trackEvent(port.name, port.details)); break;
                case 'TrackError':      analytics.then(a => a.trackError(port.name, port.details)); errorTracking.then(e => e.trackError(port.name, port.details)); break;
                default: console.error('Unsupported Elm message', port); break;
            }
        }, 100)
    })

    function click(id) {
        getElementById(id).click()
    }
    function mousedown(id) {
        getElementById(id).dispatchEvent(new Event('mousedown'))
    }
    function focus(id) {
        getElementById(id).focus()
    }
    function blur(id) {
        getElementById(id).blur()
    }
    function scrollTo(id, position) {
        maybeElementById(id).forEach(e => e.scrollIntoView(position !== 'end'))
    }
    function setClasses(html, body) {
        document.getElementsByTagName('html')[0].setAttribute('class', html)
        document.getElementsByTagName('body')[0].setAttribute('class', body)
    }
    function autofocusWithin(id) {
        getElementById(id).querySelector('[autofocus]')?.focus()
    }

    const projectPrefix = 'project-'
    function loadProjects() {
        const values = Object.keys(localStorage)
            .filter(key => key.startsWith(projectPrefix))
            .map(key => [key.replace(projectPrefix, ''), safeParse(localStorage.getItem(key))])
        window.projects = values.reduce((acc, [id, p]) => ({...acc, [id]: p}), {})
        sendToElm({kind: 'GotProjects', projects: values})
    }
    function saveProject(project) {
        const key = projectPrefix + project.id
        // setting dates should be done in Elm but can't find how to run a Task before calling a Port
        const now = Date.now()
        project.updatedAt = now
        if (localStorage.getItem(key) === null) { project.createdAt = now }
        try {
            localStorage.setItem(key, JSON.stringify(project))
            loadProjects()
        } catch (e) {
            if (e.code === DOMException.QUOTA_EXCEEDED_ERR) {
                showMessage({kind: 'error', message: "Can't save project, storage quota exceeded. Use a smaller schema or clean unused projects."})
            } else {
                showMessage({kind: 'error', message: "Can't save project: " + e.message})
            }
            const name = 'local-storage'
            const details = {error: e.name, message: e.message}
            analytics.then(a => a.trackError(name, details)); errorTracking.then(e => e.track(name, details));
        }
    }
    function dropProject(project) {
        localStorage.removeItem(projectPrefix + project.id)
        loadProjects()
    }

    function getLocalFile(maybeProjectId, maybeSourceId, file) {
        const reader = new FileReader()
        reader.onload = e => sendToElm({
            kind: 'GotLocalFile',
            now: Date.now(),
            projectId: maybeProjectId || randomUID(),
            sourceId: maybeSourceId || randomUID(),
            file, content: e.target.result
        })
        reader.readAsText(file)
    }

    function getRemoteFile(maybeProjectId, maybeSourceId, url, sample) {
        fetch(url)
            .then(res => res.text())
            .then(content => sendToElm({
                kind: 'GotRemoteFile',
                now: Date.now(),
                projectId: maybeProjectId || randomUID(),
                sourceId: maybeSourceId || randomUID(),
                url,
                content,
                sample
            }))
            .catch(err => showMessage({kind: 'error', message: err}))
    }

    function getSourceId(src, ref) {
        sendToElm({kind: 'GotSourceId', now: Date.now(), sourceId: randomUID(), src, ref})
    }

    const resizeObserver = new ResizeObserver(entries => {
        const sizes = entries.map(entry => ({
            id: entry.target.id,
            position: {
                left: entry.target.offsetLeft,
                top: entry.target.offsetTop
            },
            size: {
                width: entry.contentRect.width,
                height: entry.contentRect.height
            },
            seeds: {
                left: Math.random(),
                top: Math.random()
            }
        }))
        sendToElm({kind: 'GotSizes', sizes: sizes})
    })
    function observeSizes(ids) {
        ids.flatMap(maybeElementById).forEach(elt => resizeObserver.observe(elt))
    }

    const hotkeys = {}
    // keydown is needed for preventDefault, also can't use Elm Browser.Events.onKeyUp because of it
    document.addEventListener('keydown', e => {
        const matches = (hotkeys[e.key] || []).filter(hotkey =>
            (hotkey.ctrl === e.ctrlKey) &&
            (!hotkey.shift || e.shiftKey) &&
            (hotkey.alt === e.altKey) &&
            (hotkey.meta === e.metaKey) &&
            ((!hotkey.target && (hotkey.onInput || e.target.localName !== 'input')) ||
                (hotkey.target &&
                    (!hotkey.target.id || hotkey.target.id === e.target.id) &&
                    (!hotkey.target.class || e.target.className.split(' ').includes(hotkey.target.class)) &&
                    (!hotkey.target.tag || hotkey.target.tag === e.target.localName)))
        )
        matches.map(hotkey => {
            if (hotkey.preventDefault) { e.preventDefault() }
            sendToElm({kind: 'GotHotkey', id: hotkey.id})
        })
        if(matches.length === 0 && e.key === "Escape" && e.target.localName === 'input') { e.target.blur() }
    })
    function listenHotkeys(keys) {
        Object.keys(hotkeys).forEach(key => hotkeys[key] = [])
        Object.entries(keys).forEach(([id, alternatives]) => {
            alternatives.forEach(hotkey => {
                if (!hotkeys[hotkey.key]) {
                    hotkeys[hotkey.key] = []
                }
                hotkeys[hotkey.key].push({...hotkey, id})
            })
        })
    }

    // listen at every click to handle tracked events
    document.addEventListener('click', event => {
        const tracked = findParent(event.target, e => e.getAttribute('data-track-event'))
        if (tracked) {
            const eventName = tracked.getAttribute('data-track-event')
            const details = {label: tracked.textContent.trim()}
            for (const attr of event.target.attributes) {
                if (attr.name.startsWith('data-track-event-')) {
                    details[attr.name.replace('data-track-event-', '')] = attr.value
                }
            }
            analytics.then(a => a.trackEvent(eventName, details))
        }
    })


    /* Tracking */

    function initAnalytics(shouldTrack) {
        if (shouldTrack) {
            const waitSplitbee = (resolve, reject, timeout) => {
                if (timeout <= 0) {
                    reject()
                } else if (splitbee) {
                    resolve({
                        trackPage: name => { /* automatically tracked, do nothing */ },
                        trackEvent: (name, details) => { splitbee.track(name, details) },
                        trackError: (name, details) => { /* don't track errors in splitbee */ }
                    })
                } else {
                    setTimeout(() => {
                        waitSplitbee(resolve, reject, timeout - 100)
                    }, 100)
                }
            }
            return new Promise((resolve, reject) => waitSplitbee(resolve, reject, 3000))
        } else {
            return Promise.resolve({
                trackPage: name => console.log('analytics.page', name),
                trackEvent: (name, details) => console.log('analytics.event', name, details),
                trackError: (name, details) => console.log('analytics.error', name, details)
            })
        }
    }

    function initErrorTracking(shouldTrack) {
        if (shouldTrack) {
            // see https://sentry.io
            // initial: https://js.sentry-cdn.com/268b122ecafb4f20b6316b87246e509c.min.js
            return loadScript('/assets/sentry-268b122ecafb4f20b6316b87246e509c.min.js').then(() => ({
                trackError: (name, details) => Sentry.captureException(new Error(JSON.stringify({name, ...details})))
            }))
        } else {
            return Promise.resolve({
                trackError: (name, details) => console.log('error.track', name, details)
            })
        }
    }

    function showMessage({kind, message}) {
        // TODO track message in sentry and show it in toast using ports
        switch (kind) {
            case 'error': console.error(message); break;
            case 'warn': console.warn(message); break;
            case 'log': console.log(message); break;
            default: console.error(message)
        }
    }


    /* Libs */

    function getElementById(id) {
        const elem = document.getElementById(id)
        if (elem) {
            return elem
        } else {
            throw new Error(`Can't find element with id '${id}'`)
        }
    }

    function maybeElementById(id) {
        const elem = document.getElementById(id)
        return elem ? [elem] : []
    }

    function getParents(elt) {
        const parents = [elt]
        let parent = elt.parentElement
        while (parent) {
            parents.push(parent)
            parent = parent.parentElement
        }
        return parents
    }

    function findParent(elt, predicate) {
        if (predicate(elt)) {
            return elt
        } else if (elt.parentElement) {
            return findParent(elt.parentElement, predicate)
        } else {
            return undefined
        }
    }

    function safeParse(text) {
        try {
            return JSON.parse(text)
        } catch (e) {
            return text
        }
    }

    function randomUID() {
        return uuidv4()
    }

    function loadScript(url) {
        return new Promise((resolve, reject) => {
            const script = document.createElement('script')
            script.src = url
            script.type='text/javascript'
            script.addEventListener('load', resolve)
            script.addEventListener('error', reject)
            document.getElementsByTagName('head')[0].appendChild(script)
        })
    }

    /* polyfills */

    // https://developer.mozilla.org/fr/docs/Web/JavaScript/Reference/Global_Objects/String/includes
    if (!String.prototype.includes) {
        String.prototype.includes = function(search, start) {
            'use strict';
            if (search instanceof RegExp) {
                throw TypeError('first argument must not be a RegExp');
            }
            if (start === undefined) { start = 0; }
            return this.indexOf(search, start) !== -1;
        };
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
})
