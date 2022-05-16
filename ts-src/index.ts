import {
    GetLocalFileMsg,
    GetRemoteFileMsg,
    Hotkey,
    HotkeyId,
    ListenKeysMsg,
    LoadRemoteProjectMsg,
    MoveProjectToMsg,
    ObserveSizesMsg,
    SaveProjectMsg,
    SetMetaMsg
} from "./types/elm";
import {ElmApp} from "./services/elm";
import {AzimuttApi} from "./services/api";
import {Project} from "./types/project";
import {Analytics, LogAnalytics, SplitbeeAnalytics} from "./services/analytics";
import {ErrLogger, LogErrLogger, SentryErrLogger} from "./services/errors";
import {IndexedDBStorage} from "./storages/indexeddb";
import {LocalStorageStorage} from "./storages/localstorage";
import {InMemoryStorage} from "./storages/inmemory";
import {ConsoleLogger} from "./services/logger";
import {loadPolyfills} from "./utils/polyphills";
import {Utils} from "./utils/utils";
import {SupabaseInitializer} from "./services/supabase";

const env = Utils.getEnv()
const logger = new ConsoleLogger(env)
const initializer = SupabaseInitializer.init({
    // FIXME: inject this values from conf
    supabaseUrl: 'https://ywieybitcnbtklzsfxgd.supabase.co',
    supabaseKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Inl3aWV5Yml0Y25idGtsenNmeGdkIiwicm9sZSI6ImFub24iLCJpYXQiOjE2NTE5MjI3MzUsImV4cCI6MTk2NzQ5ODczNX0.ccfB_pVemOqeR4CwhSoGmwfT5bx-FAuY24IbGj7OjiE'
})
const app = ElmApp.init({now: Date.now(), user: initializer.getLoggedUser()}, logger)
const supabase = initializer.init(app, logger)
const skipAnalytics = !!JSON.parse(localStorage.getItem('skip-analytics') || 'false')
const analytics: Promise<Analytics> = env === 'prod' && !skipAnalytics ? SplitbeeAnalytics.init() : Promise.resolve(new LogAnalytics(logger))
const errorTracking: Promise<ErrLogger> = env === 'prod' ? SentryErrLogger.init() : Promise.resolve(new LogErrLogger(logger))
const store = IndexedDBStorage.init(logger).catch(() => LocalStorageStorage.init(logger)).catch(() => new InMemoryStorage())
logger.info('Hi there! I hope you are enjoying Azimutt 👍️\n\n' +
    'Did you know you can access your current project in the console?\n' +
    'And even trigger some actions in Azimutt?\n\n' +
    'Just look at `azimutt` variable and perform what you want.\n' +
    'For example, here is how to count the total number of columns in all sources:\n' +
    '  `azimutt.project.sources.flatMap(s => s.tables).flatMap(t => t.columns).length`\n\n' +
    'Use `azimutt.help()` for more details!')

window.azimutt = new AzimuttApi(app, logger)

/* PWA service worker */

if ('serviceWorker' in navigator && env === 'prod') {
    navigator.serviceWorker.register("/service-worker.js")
        // .then(reg => logger.debug('service-worker registered!', reg))
        // .catch(err => logger.debug('service-worker failed to register!', err))
}

/* Elm ports */

app.on('Click', msg => Utils.getElementById(msg.id).click())
app.on('MouseDown', msg => Utils.getElementById(msg.id).dispatchEvent(new Event('mousedown')))
app.on('Focus', msg => Utils.getElementById(msg.id).focus())
app.on('Blur', msg => Utils.getElementById(msg.id).blur())
app.on('ScrollTo', msg => Utils.maybeElementById(msg.id).forEach(e => e.scrollIntoView(msg.position !== 'end')))
app.on('Fullscreen', msg => Utils.fullscreen(msg.maybeId))
app.on('SetMeta', setMeta)
app.on('AutofocusWithin', msg => (Utils.getElementById(msg.id).querySelector<HTMLElement>('[autofocus]'))?.focus())
app.on('Login', msg => supabase.login(msg.redirect))
app.on('Logout', supabase.logout)
app.on('LoadProjects', loadProjects)
app.on('LoadRemoteProject', loadRemoteProject)
app.on('SaveProject', msg => saveProject(msg, loadProjects))
app.on('MoveProjectTo', moveProjectTo)
app.on('DownloadFile', msg => Utils.downloadFile(msg.filename, msg.content))
app.on('DropProject', msg => (msg.project.storage === 'cloud' ? supabase.dropProject(msg.project) : store.then(s => s.dropProject(msg.project))).then(_ => loadProjects()))
app.on('GetLocalFile', getLocalFile)
app.on('GetRemoteFile', getRemoteFile)
app.on('ObserveSizes', observeSizes)
app.on('ListenKeys', listenHotkeys)
app.on('TrackPage', msg => analytics.then(a => a.trackPage(msg.name)))
app.on('TrackEvent', msg => analytics.then(a => a.trackEvent(msg.name, msg.details)))
app.on('TrackError', msg => {
    analytics.then(a => a.trackError(msg.name, msg.details))
    errorTracking.then(e => e.trackError(msg.name, msg.details))
})
if(app.noListeners().length > 0) {
    logger.error(`Do not listen to elm events: ${app.noListeners().join(', ')}`)
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

function loadRemoteProject(msg: LoadRemoteProjectMsg) {
    fetch(msg.projectUrl)
        .then(res => res.json())
        .then((project: Project) => app.loadProjects([project]))
        .catch(err => {
            app.loadProjects([])
            app.toast('error', `Can't load remote project: ${err}`)
        })
}

function loadProjects() {
    // FIXME: load projects in several steps (local are faster than remote)
    Promise.all([store.then(s => s.loadProjects()), supabase.loadProjects()]).then((allProjects: Project[][]) => {
        const projects = allProjects.flat()
        app.loadProjects(projects)
        window.azimutt.projects = projects.reduce((acc, p) => ({...acc, [p.id]: p}), {})
        const [_, id] = window.location.pathname.match(/^\/projects\/([0-9a-f-]{36})/) || []
        id ? window.azimutt.project = window.azimutt.projects[id] : undefined
    })
}
function saveProject(msg: SaveProjectMsg, callback: () => void) {
    const storing = msg.project.storage === 'cloud' ? supabase.saveProject(msg.project) : store.then(s => s.saveProject(msg.project))
    storing
        .then(_ => app.toast('success', 'Project saved'))
        .then(_ => callback())
        .catch(e => {
            let message
            if (typeof e === 'string') {
                message = e
            } else if (e.code === DOMException.QUOTA_EXCEEDED_ERR) {
                message = "Can't save project, storage quota exceeded. Use a smaller schema or clean unused ones."
            } else {
                message = 'Unknown localStorage error: ' + e.message
            }
            app.toast('error', message)
            const name = 'local-storage'
            const details = typeof e === 'string' ? {error: e} : {error: e.name, message: e.message}
            analytics.then(a => a.trackError(name, details))
            errorTracking.then(e => e.trackError(name, details))
        })
}
async function moveProjectTo(msg: MoveProjectToMsg): Promise<void> {
    if (msg.project.storage === 'cloud') {
        if (msg.storage === 'browser') {
            msg.project.storage = msg.storage
            return await store.then(s => s.saveProject(msg.project))
                .then(_ => supabase.dropProject(msg.project))
                .then(_ => app.toast('success', 'Project moved to browser storage'))
        }
    } else if (msg.project.storage === 'browser' || msg.project.storage === undefined) {
        if (msg.storage === 'cloud') {
            msg.project.storage = msg.storage
            return await supabase.saveProject(msg.project)
                .then(_ => store.then(s => s.dropProject(msg.project)))
                .then(_ => app.toast('success', 'Project moved to cloud storage'))
        }
    }
    return app.toast('warning', `Unable to move project from ${msg.project.storage} to ${msg.storage}`)
}

function getLocalFile(msg: GetLocalFileMsg) {
    const reader = new FileReader()
    reader.onload = (e: any) => app.gotLocalFile(msg, e.target.result)
    reader.readAsText(msg.file as any)
}

function getRemoteFile(msg: GetRemoteFileMsg) {
    fetch(msg.url)
        .then(res => res.text())
        .then(content => app.gotRemoteFile(msg, content))
        .catch(err => app.toast('error', `Can't get remote file ${msg.url}: ${err}`))
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
    app.updateSizes(sizes)
})
function observeSizes(msg: ObserveSizesMsg) {
    msg.ids.flatMap(Utils.maybeElementById).forEach(elt => resizeObserver.observe(elt))
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
        app.gotHotkey(hotkey)
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
            app.gotKeyHold(e.code, true)
        }
        holdKeyState.drag = true
    }
}
function keyupHoldKey(e: KeyboardEvent) {
    if (e.code === 'Space') {
        if (holdKeyState.drag) {
            app.gotKeyHold(e.code, false)
        }
        holdKeyState.drag = false
    }
}


// listen at every click to handle tracking events
function trackClick(e: MouseEvent) {
    const target = e.target as HTMLElement
    const tracked = Utils.findParent(target, e => !!e.getAttribute('data-track-event'))
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

loadPolyfills()
