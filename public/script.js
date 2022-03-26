import { Elm } from '../.elm-spa/defaults/Main.elm'

    console.info('Hi there! I hope you are enjoying Azimutt 👍️\n\n' +
        'Did you know you can access your current project in the console?\n' +
        'And even trigger some actions in Azimutt?\n\n' +
        'Just look at `azimutt` variable and perform what you want.\n' +
        'For example, here is how to count the total number of columns in all sources:\n' +
        '  `azimutt.project.sources.flatMap(s => s.tables).flatMap(t => t.columns).length`\n\n' +
        'Use `azimutt.help()` for more details!')

    const isDev = window.location.hostname === 'localhost'
    const isProd = window.location.hostname === 'azimutt.app'
    const skipAnalytics = !!JSON.parse(localStorage.getItem('skip-analytics'))
    const analytics = initAnalytics(isProd && !skipAnalytics)
    const errorTracking = initErrorTracking(isProd)
    const flags = {now: Date.now()}
    const app = Elm.Main.init({flags})

    /* JavaScript API */

    window.azimutt = {
        showTable: tableId => sendToElm({kind: 'GotShowTable', id: tableId}),
        hideTable: tableId => sendToElm({kind: 'GotHideTable', id: tableId}),
        showColumn: columnRef => sendToElm({kind: 'GotShowColumn', ref: columnRef}),
        hideColumn: columnRef => sendToElm({kind: 'GotHideColumn', ref: columnRef}),
        selectTable: tableId => sendToElm({kind: 'GotSelectTable', id: tableId}),
        moveTable: (tableId, dx, dy) => sendToElm({kind: 'GotMoveTable', id: tableId, dx, dy}),
        moveColumn: (columnRef, index) => sendToElm({kind: 'GotMoveColumn', ref: columnRef, index}),
        fitToScreen: () => sendToElm({kind: 'GotFitToScreen'}),
        help: () => console.info('Hi! Welcome in the hackable world! 💻️🤓\n' +
            'We are just trying out this, so if you use it and it\'s helpful, please let us know. Also, if you need more feature like this, don\'t hesitate to ask.\n\n' +
            'Here are a few tips:\n' +
            ' - `tableId` is the "schema.table" of a table, but if schema is "public", you can omit it. Basically, what you see in table header.\n' +
            ' - `columnRef` is similar to `tableId` but with the column name appended. For example "users.id" or "audit.logs.time".')
    }


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
        // TODO: use requestAnimationFrame instead!
        setTimeout(() => {
            // console.log('elm message', port)
            switch (port.kind) {
                case 'Click':             click(port.id); break;
                case 'MouseDown':         mousedown(port.id); break;
                case 'Focus':             focus(port.id); break;
                case 'Blur':              blur(port.id); break;
                case 'ScrollTo':          scrollTo(port.id, port.position); break;
                case 'Fullscreen':        fullscreen(port.maybeId); break;
                case 'SetMeta':           setMeta(port); break;
                case 'AutofocusWithin':   autofocusWithin(port.id); break;
                case 'LoadProjects':      loadProjects(); break;
                case 'LoadRemoteProject': loadRemoteProject(port.projectUrl); break;
                case 'SaveProject':       saveProject(port.project, loadProjects); break;
                case 'DownloadFile':      downloadFile(port.filename, port.content); break;
                case 'DropProject':       dropProject(port.project); break;
                case 'GetLocalFile':      getLocalFile(port.project, port.source, port.file); break;
                case 'GetRemoteFile':     getRemoteFile(port.project, port.source, port.url, port.sample); break;
                case 'GetSourceId':       getSourceId(port.src, port.ref); break;
                case 'ObserveSizes':      observeSizes(port.ids); break;
                case 'ListenKeys':        listenHotkeys(port.keys); break;
                case 'TrackPage':         analytics.then(a => a.trackPage(port.name)); break;
                case 'TrackEvent':        analytics.then(a => a.trackEvent(port.name, port.details)); break;
                case 'TrackError':        analytics.then(a => a.trackError(port.name, port.details)); errorTracking.then(e => e.trackError(port.name, port.details)); break;
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
    function fullscreen(maybeId) {
        const element = maybeId ? getElementById(maybeId) : document.body
        const result = element.requestFullscreen ? element.requestFullscreen() : Promise.reject(new Error('requestFullscreen not available'))
        result.catch(_ => window.open(window.location.href, '_blank').focus()) // if full-screen is denied, open in a new tab
    }
    function setMeta(meta) {
        if (meta.title) {
            document.title = meta.title
            document.querySelector('meta[property="og:title"]')?.setAttribute('content', meta.title)
            document.querySelector('meta[name="twitter:title"]')?.setAttribute('content', meta.title)
        }
        if (meta.description) {
            document.querySelector('meta[name="description"]')?.setAttribute('content', meta.description)
            document.querySelector('meta[property="og:description"]')?.setAttribute('content', meta.description)
            document.querySelector('meta[name="twitter:description"]')?.setAttribute('content', meta.description)
        }
        if (meta.canonical) {
            document.querySelector('link[rel="canonical"]')?.setAttribute('href', meta.canonical)
            document.querySelector('meta[property="og:url"]')?.setAttribute('content', meta.canonical)
            document.querySelector('meta[name="twitter:url"]')?.setAttribute('content', meta.canonical)
        }
        if (meta.html) { document.getElementsByTagName('html')[0]?.setAttribute('class', meta.html) }
        if (meta.body) { document.getElementsByTagName('body')[0]?.setAttribute('class', meta.body) }
    }
    function autofocusWithin(id) {
        getElementById(id).querySelector('[autofocus]')?.focus()
    }

    function loadRemoteProject(projectUrl) {
        fetch(projectUrl)
            .then(res => res.json())
            .then(project => sendToElm({kind: 'GotProjects', projects: [[project.id, project]]}))
            .catch(err => {
                sendToElm({kind: 'GotProjects', projects: []})
                sendToElm({kind: 'GotToast', level: 'error', message: `Can't load remote project: ${err}`})
            })
    }

    const databaseName = 'azimutt'
    const databaseVersion = 1
    const dbProjects = 'projects'
    function getConfiguredDb() {
        return new Promise((resolve, reject) => {
            function handleIndexedDBError(event) {
                console.warn('IndexedDB not available', event)
                reject(new Error('IndexedDB not available'))
                alert("Azimutt needs IndexedDB but it's not available, please make it available or use a browser that support it!")
            }
            if (!window.indexedDB) {
                handleIndexedDBError(undefined)
            } else {
                const openRequest = window.indexedDB.open(databaseName, databaseVersion)
                openRequest.onerror = event => handleIndexedDBError(event)
                openRequest.onsuccess = function(event) {
                    const db = event.target.result
                    db.onerror = e => handleIndexedDBError(e)
                    resolve(db)
                }
                openRequest.onupgradeneeded = function() {
                    const db = openRequest.result
                    if (!db.objectStoreNames.contains(dbProjects)) {
                        db.createObjectStore(dbProjects, {keyPath: 'id'})
                    }
                }
            }
        })
    }
    function getDbObjectStore(objectStore, transactionType) {
        return new Promise((resolve, reject) => {
            getConfiguredDb().then(db => {
                const transaction = db.transaction(
                    objectStore,
                    typeof transactionType === 'undefined' ? 'readonly' : transactionType
                )
                resolve(transaction.objectStore(objectStore))
            }, reject)
        })
    }

    const localStorageProjectPrefix = 'project-'
    function getLocalStorageProjects() {
        return Object.keys(localStorage)
            .filter(key => key.startsWith(localStorageProjectPrefix))
            .map(key => safeParse(localStorage.getItem(key)))
    }
    function dropLocalStorageProject(project) {
        localStorage.removeItem(localStorageProjectPrefix + project.id)
    }
    function loadAndMigrateLocaleStorageProjects() {
        const projects = getLocalStorageProjects()
        projects.forEach(p => saveProject(p, () => dropLocalStorageProject(p)))
        return projects
    }

    function loadProjects() {
        if (window.indexedDB) {
            getDbObjectStore(dbProjects).then(store => {
                let projects = []
                store.openCursor().onsuccess = event => {
                    const cursor = event.target.result
                    if (cursor) {
                        projects.push(cursor.value)
                        cursor.continue()
                    } else {
                        projects = projects.concat(loadAndMigrateLocaleStorageProjects())
                        sendToElm({kind: 'GotProjects', projects: projects.map(p => [p.id, p])})
                        window.azimutt.projects = projects.reduce((acc, p) => ({...acc, [p.id]: p}), {})
                        const [_, id] = window.location.pathname.match(/^\/projects\/([0-9a-f-]{36})/) || []
                        id ? window.azimutt.project = window.azimutt.projects[id] : undefined
                    }
                }
            })
        } else if (window.localStorage) {
            const projects = getLocalStorageProjects()
            sendToElm({kind: 'GotProjects', projects: projects.map(p => [p.id, p])})
            window.azimutt.projects = projects.reduce((acc, [id, p]) => ({...acc, [id]: p}), {})
            const [_, id] = window.location.pathname.match(/^\/projects\/([0-9a-f-]{36})/) || []
            id ? window.azimutt.project = window.azimutt.projects[id] : undefined
        } else {
            alert('Azimutt needs IndexedDB or LocalStorage to store projects locally, but they are not available. ' +
                'Please make them available or use a browser that support them!')
        }
    }
    function saveProject(project, callback) {
        const now = Date.now()
        project.updatedAt = now

        if (window.indexedDB) {
            getDbObjectStore(dbProjects, 'readwrite').then(store => {
                if (!store.get(project.id)) {
                    project.createdAt = now
                    store.add(project).onsuccess = callback
                } else {
                    store.put(project).onsuccess = callback
                }
            })
        } else if (window.localStorage) {
            const key = localStorageProjectPrefix + project.id
            if (localStorage.getItem(key) === null) { project.createdAt = now }
            try {
                localStorage.setItem(key, JSON.stringify(project))
            } catch (e) {
                let message
                if (e.code === DOMException.QUOTA_EXCEEDED_ERR) {
                    message = "Can't save project, storage quota exceeded. Use a smaller schema or clean unused ones."
                } else {
                    message = 'Unknown localStorage error: ' + e.message
                }
                showMessage({kind: 'error', message})
                const name = 'local-storage'
                const details = {error: e.name, message: e.message}
                analytics.then(a => a.trackError(name, details)); errorTracking.then(e => e.track(name, details));
            }
            callback()
        } else {
            alert('Azimutt needs IndexedDB or LocalStorage to store projects locally, but they are not available. ' +
                'Please make them available or use a browser that support them!')
        }
    }
    function dropProject(project) {
        if (window.indexedDB) {
            getDbObjectStore(dbProjects, 'readwrite').then(store => {
                store.delete(project.id).onsuccess = loadProjects
            })
        } else if (window.localStorage) {
            localStorage.removeItem(localStorageProjectPrefix + project.id)
            loadProjects()
        } else {
            alert('Azimutt needs IndexedDB or LocalStorage to store projects locally, but they are not available. ' +
                'Please make them available or use a browser that support them!')
        }
    }

    function getLocalFile(maybeProjectId, maybeSourceId, file) {
        const reader = new FileReader()
        reader.onload = e => sendToElm({
            kind: 'GotLocalFile',
            now: Date.now(),
            projectId: maybeProjectId || randomUID(),
            sourceId: maybeSourceId || randomUID(),
            file,
            content: e.target.result
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
            .catch(err => showMessage({kind: 'error', message: `Can't get remote file ${url}: ${err}`}))
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
    function keydownHotkey(e) {
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
    }
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


    // handle key hold
    const holdKeyState = {}
    function keydownHoldKey(e) {
        if (e.code === 'Space') {
            if (!holdKeyState['drag'] && e.target.localName !== 'input') {
                sendToElm({kind: 'GotKeyHold', key: e.code, start: true})
            }
            holdKeyState['drag'] = true
        }
    }
    function keyupHoldKey(e) {
        if (e.code === 'Space') {
            if (holdKeyState['drag']) {
                sendToElm({kind: 'GotKeyHold', key: e.code, start: false})
            }
            holdKeyState['drag'] = false
        }
    }


    // listen at every click to handle tracking events
    function trackClick(e) {
        const tracked = findParent(e.target, e => e.getAttribute('data-track-event'))
        if (tracked) {
            const eventName = tracked.getAttribute('data-track-event')
            const details = {label: tracked.textContent.trim()}
            for (const attr of e.target.attributes) {
                if (attr.name.startsWith('data-track-event-')) {
                    details[attr.name.replace('data-track-event-', '')] = attr.value
                }
            }
            analytics.then(a => a.trackEvent(eventName, details))
        }
    }

    // listeners
    document.addEventListener('click', e => {
        trackClick(e)
    })
    document.addEventListener('keydown', e => {
        keydownHotkey(e)
        keydownHoldKey(e)
    })
    document.addEventListener('keyup', e => {
        keyupHoldKey(e)
    })


    /* Tracking */

    function initAnalytics(shouldTrack) {
        if (shouldTrack) {
            const waitSplitbee = (resolve, reject, timeout) => {
                if (timeout <= 0) {
                    reject(new Error('Splitbee not available'))
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
            case 'error': console.error(message); alert(message); break;
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

    function downloadFile(filename, content) {
        const element = document.createElement('a');
        element.setAttribute('href', 'data:text/plain;charset=utf-8,' + encodeURIComponent(content));
        element.setAttribute('download', filename);

        element.style.display = 'none';
        document.body.appendChild(element);

        element.click();

        document.body.removeChild(element);
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
