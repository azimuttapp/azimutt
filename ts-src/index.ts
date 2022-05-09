import {
    AutofocusWithinMsg,
    BlurMsg,
    ClickMsg, DownloadFileMsg, DropProjectMsg,
    FocusMsg,
    FullscreenMsg, GetLocalFileMsg, GetRemoteFileMsg, Hotkey, HotkeyId, ListenKeysMsg,
    LoadRemoteProjectMsg,
    MouseDownMsg, ObserveSizesMsg, SaveProjectMsg,
    ScrollToMsg,
    SetMetaMsg
} from "./types/elm";
import {ElmApp} from "./elm";
import {AzimuttApiImpl} from "./api";
import {Project} from "./types/project";
import {Analytics, ConsoleAnalytics, SplitbeeAnalytics} from "./analytics";
import {ConsoleErrLogger, ErrLogger, SentryErrLogger} from "./errors";
import {IndexedDBStorage} from "./storages/indexeddb";
import {LocalStorageStorage} from "./storages/localstorage";
import {InMemoryStorage} from "./storages/inmemory";
import {HtmlId} from "./types/basics";

console.info('Hi there! I hope you are enjoying Azimutt 👍️\n\n' +
    'Did you know you can access your current project in the console?\n' +
    'And even trigger some actions in Azimutt?\n\n' +
    'Just look at `azimutt` variable and perform what you want.\n' +
    'For example, here is how to count the total number of columns in all sources:\n' +
    '  `azimutt.project.sources.flatMap(s => s.tables).flatMap(t => t.columns).length`\n\n' +
    'Use `azimutt.help()` for more details!')

const isDev = window.location.hostname === 'localhost'
const isProd = window.location.hostname === 'azimutt.app'
const skipAnalytics = !!JSON.parse(localStorage.getItem('skip-analytics') || 'false')
const analytics: Promise<Analytics> = isProd && !skipAnalytics ? SplitbeeAnalytics.init() : Promise.resolve(new ConsoleAnalytics())
const errorTracking: Promise<ErrLogger> = isProd ? SentryErrLogger.init() : Promise.resolve(new ConsoleErrLogger())
const app = ElmApp.init({now: Date.now()})

window.azimutt = new AzimuttApiImpl(app)

/* PWA service worker */

if ('serviceWorker' in navigator && isProd) {
    navigator.serviceWorker.register("/service-worker.js")
    // .then(reg => console.log('service-worker registered!', reg))
    // .catch(err => console.log('service-worker failed to register!', err))
}

/* Elm ports */

app.subscribe(msg => {
    // console.log('elm message', msg)
    switch (msg.kind) {
        case 'Click':             click(msg); break;
        case 'MouseDown':         mousedown(msg); break;
        case 'Focus':             focus(msg); break;
        case 'Blur':              blur(msg); break;
        case 'ScrollTo':          scrollTo(msg); break;
        case 'Fullscreen':        fullscreen(msg); break;
        case 'SetMeta':           setMeta(msg); break;
        case 'AutofocusWithin':   autofocusWithin(msg); break;
        case 'LoadProjects':      loadProjects(); break;
        case 'LoadRemoteProject': loadRemoteProject(msg); break;
        case 'SaveProject':       saveProject(msg, loadProjects); break;
        case 'DownloadFile':      downloadFile(msg); break;
        case 'DropProject':       dropProject(msg); break;
        case 'GetLocalFile':      getLocalFile(msg); break;
        case 'GetRemoteFile':     getRemoteFile(msg); break;
        case 'ObserveSizes':      observeSizes(msg); break;
        case 'ListenKeys':        listenHotkeys(msg); break;
        case 'TrackPage':         analytics.then(a => a.trackPage(msg.name)); break;
        case 'TrackEvent':        analytics.then(a => a.trackEvent(msg.name, msg.details)); break;
        case 'TrackError':        analytics.then(a => a.trackError(msg.name, msg.details)); errorTracking.then(e => e.trackError(msg.name, msg.details)); break;
        default: console.error('Unsupported Elm message', msg); break;
    }
})

function click(msg: ClickMsg) {
    getElementById(msg.id).click()
}
function mousedown(msg: MouseDownMsg) {
    getElementById(msg.id).dispatchEvent(new Event('mousedown'))
}
function focus(msg: FocusMsg) {
    getElementById(msg.id).focus()
}
function blur(msg: BlurMsg) {
    getElementById(msg.id).blur()
}
function scrollTo(msg: ScrollToMsg) {
    maybeElementById(msg.id).forEach(e => e.scrollIntoView(msg.position !== 'end'))
}
function fullscreen(msg: FullscreenMsg) {
    const element = msg.maybeId ? getElementById(msg.maybeId) : document.body
    const result = element.requestFullscreen ? element.requestFullscreen() : Promise.reject(new Error('requestFullscreen not available'))
    result.catch(_ => window.open(window.location.href, '_blank')?.focus()) // if full-screen is denied, open in a new tab
}
function setMeta(meta: SetMetaMsg) {
    if (typeof meta.title === 'string') {
        document.title = meta.title
        document.querySelector('meta[property="og:title"]')?.setAttribute('content', meta.title)
        document.querySelector('meta[name="twitter:title"]')?.setAttribute('content', meta.title)
    }
    if (typeof meta.description === 'string') {
        document.querySelector('meta[name="description"]')?.setAttribute('content', meta.description)
        document.querySelector('meta[property="og:description"]')?.setAttribute('content', meta.description)
        document.querySelector('meta[name="twitter:description"]')?.setAttribute('content', meta.description)
    }
    if (typeof meta.canonical === 'string') {
        const canonical = document.querySelector('link[rel="canonical"]')
        canonical ? canonical.setAttribute('href', meta.canonical) : document.head.append(`<link rel="canonical" href="${meta.canonical}">`)
        document.querySelector('meta[property="og:url"]')?.setAttribute('content', meta.canonical)
        document.querySelector('meta[name="twitter:url"]')?.setAttribute('content', meta.canonical)
    }
    if (typeof meta.html === 'string') { document.getElementsByTagName('html')[0]?.setAttribute('class', meta.html) }
    if (typeof meta.body === 'string') { document.getElementsByTagName('body')[0]?.setAttribute('class', meta.body) }
}
function autofocusWithin(msg: AutofocusWithinMsg) {
    (getElementById(msg.id).querySelector('[autofocus]') as HTMLElement | null)?.focus()
}

function loadRemoteProject(msg: LoadRemoteProjectMsg) {
    fetch(msg.projectUrl)
        .then(res => res.json())
        .then((project: Project) => app.send({kind: 'GotProjects', projects: [[project.id, project]]}))
        .catch(err => {
            app.send({kind: 'GotProjects', projects: []})
            app.send({kind: 'GotToast', level: 'error', message: `Can't load remote project: ${err}`})
        })
}

const store = IndexedDBStorage.init().catch(() => LocalStorageStorage.init()).catch(() => new InMemoryStorage())

function loadProjects() {
    store.then(s => s.loadProjects()).then((projects: Project[]) => {
        app.send({kind: 'GotProjects', projects: projects.map(p => [p.id, p])})
        window.azimutt.projects = projects.reduce((acc, p) => ({...acc, [p.id]: p}), {})
        const [_, id] = window.location.pathname.match(/^\/projects\/([0-9a-f-]{36})/) || []
        id ? window.azimutt.project = window.azimutt.projects[id] : undefined
    })
}
function saveProject(msg: SaveProjectMsg, callback: () => void) {
    store.then(s => s.saveProject(msg.project)).then(_ => {
        callback()
    }).catch(e => {
        let message
        if(typeof e === 'string') {
            message = e
        } else if (e.code === DOMException.QUOTA_EXCEEDED_ERR) {
            message = "Can't save project, storage quota exceeded. Use a smaller schema or clean unused ones."
        } else {
            message = 'Unknown localStorage error: ' + e.message
        }
        app.send({kind: 'GotToast', level: 'error', message})
        const name = 'local-storage'
        const details = typeof e === 'string' ? {error: e} : {error: e.name, message: e.message}
        analytics.then(a => a.trackError(name, details))
        errorTracking.then(e => e.trackError(name, details))
    })
}
function dropProject(msg: DropProjectMsg) {
    store.then(s => s.dropProject(msg.project)).then(_ => {
        loadProjects()
    })
}

function getLocalFile(msg: GetLocalFileMsg) {
    const reader = new FileReader()
    reader.onload = (e: any) => app.send({
        kind: 'GotLocalFile',
        now: Date.now(),
        projectId: msg.project || randomUID(),
        sourceId: msg.source || randomUID(),
        file: msg.file,
        content: e.target.result
    })
    reader.readAsText(msg.file as any)
}

function getRemoteFile(msg: GetRemoteFileMsg) {
    fetch(msg.url)
        .then(res => res.text())
        .then(content => app.send({
            kind: 'GotRemoteFile',
            now: Date.now(),
            projectId: msg.project || randomUID(),
            sourceId: msg.source || randomUID(),
            url: msg.url,
            content,
            sample: msg.sample
        }))
        .catch(err => app.send({kind: 'GotToast', level: 'error', message: `Can't get remote file ${msg.url}: ${err}`}))
}

const resizeObserver = new ResizeObserver(entries => {
    const sizes = entries.map(entry => ({
        id: entry.target.id,
        position: {
            left: (entry.target as HTMLElement).offsetLeft,
            top: (entry.target as HTMLElement).offsetTop
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
    app.send({kind: 'GotSizes', sizes: sizes})
})
function observeSizes(msg: ObserveSizesMsg) {
    msg.ids.flatMap(maybeElementById).forEach(elt => resizeObserver.observe(elt))
}

const hotkeys: {[key: string]: (Hotkey & {id: HotkeyId})[]} = {}
// keydown is needed for preventDefault, also can't use Elm Browser.Events.onKeyUp because of it
function isInput(elt: Element) { return elt.localName === 'input' || elt.localName === 'textarea' }
function keydownHotkey(e: KeyboardEvent) {
    const target = e.target as HTMLElement
    const matches = (hotkeys[e.key] || []).filter(hotkey => {
        return (hotkey.ctrl === e.ctrlKey) &&
            (!hotkey.shift || e.shiftKey) &&
            (hotkey.alt === e.altKey) &&
            (hotkey.meta === e.metaKey) &&
            ((!hotkey.target && (hotkey.onInput || !isInput(target))) ||
                (hotkey.target &&
                    (!hotkey.target.id || hotkey.target.id === target.id) &&
                    (!hotkey.target.class || target.className.split(' ').includes(hotkey.target.class)) &&
                    (!hotkey.target.tag || hotkey.target.tag === target.localName)))
    })
    matches.map(hotkey => {
        if (hotkey.preventDefault) { e.preventDefault() }
        app.send({kind: 'GotHotkey', id: hotkey.id})
    })
    if(matches.length === 0 && e.key === "Escape" && isInput(target)) { target.blur() }
}
function listenHotkeys(msg: ListenKeysMsg) {
    Object.keys(hotkeys).forEach(key => hotkeys[key] = [])
    Object.entries(msg.keys).forEach(([id, alternatives]) => {
        alternatives.forEach(hotkey => {
            if (!hotkeys[hotkey.key]) {
                hotkeys[hotkey.key] = []
            }
            hotkeys[hotkey.key].push({...hotkey, id})
        })
    })
}


// handle key hold
const holdKeyState = {drag: false}
function keydownHoldKey(e: KeyboardEvent) {
    if (e.code === 'Space') {
        if (!holdKeyState.drag && (e.target as Element).localName !== 'input') {
            app.send({kind: 'GotKeyHold', key: e.code, start: true})
        }
        holdKeyState.drag = true
    }
}
function keyupHoldKey(e: KeyboardEvent) {
    if (e.code === 'Space') {
        if (holdKeyState.drag) {
            app.send({kind: 'GotKeyHold', key: e.code, start: false})
        }
        holdKeyState.drag = false
    }
}


// listen at every click to handle tracking events
function trackClick(e: MouseEvent) {
    const target = e.target as HTMLElement
    const tracked = findParent(target, e => !!e.getAttribute('data-track-event'))
    if (tracked) {
        const eventName = tracked.getAttribute('data-track-event') || ''
        const details: { [key: string]: string } = {label: (tracked.textContent || '').trim()}
        const attrs = target.attributes
        for (let i = 0; i < attrs.length; i++) {
            const attr = attrs[i]
            if (attr.name.startsWith('data-track-event-')) {
                details[attr.name.replace('data-track-event-', '')] = attr.value
            }
        }
        analytics.then(a => a.trackEvent(eventName, details))
    }
}

// listeners
document.addEventListener('click', (e: MouseEvent) => {
    trackClick(e)
})
document.addEventListener('keydown', (e: KeyboardEvent) => {
    keydownHotkey(e)
    keydownHoldKey(e)
})
document.addEventListener('keyup', (e: KeyboardEvent) => {
    keyupHoldKey(e)
})


/* Libs */

function getElementById(id: HtmlId): HTMLElement {
    const elem = document.getElementById(id)
    if (elem) {
        return elem
    } else {
        throw new Error(`Can't find element with id '${id}'`)
    }
}

function maybeElementById(id: HtmlId): HTMLElement[] {
    const elem = document.getElementById(id)
    return elem ? [elem] : []
}

function getParents(elt: HTMLElement): HTMLElement[] {
    const parents = [elt]
    let parent = elt.parentElement
    while (parent) {
        parents.push(parent)
        parent = parent.parentElement
    }
    return parents
}

function findParent(elt: HTMLElement, predicate: (e: HTMLElement) => boolean): HTMLElement | undefined {
    if (predicate(elt)) {
        return elt
    } else if (elt.parentElement) {
        return findParent(elt.parentElement, predicate)
    } else {
        return undefined
    }
}

function randomUID() {
    return window.uuidv4()
}

function downloadFile(msg: DownloadFileMsg) {
    const element = document.createElement('a')
    element.setAttribute('href', 'data:text/plain;charset=utf-8,' + encodeURIComponent(msg.content))
    element.setAttribute('download', msg.filename)

    element.style.display = 'none'
    document.body.appendChild(element)

    element.click()

    document.body.removeChild(element)
}

/* polyfills */

// https://developer.mozilla.org/fr/docs/Web/JavaScript/Reference/Global_Objects/String/includes
if (!String.prototype.includes) {
    String.prototype.includes = function(search: string | RegExp, start) {
        if (search instanceof RegExp) {
            throw TypeError('first argument must not be a RegExp')
        }
        if (start === undefined) { start = 0 }
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
