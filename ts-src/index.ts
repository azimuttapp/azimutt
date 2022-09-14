import {
    GetLocalFileMsg,
    GetProjectMsg,
    Hotkey,
    HotkeyId,
    ListenKeysMsg,
    ObserveSizesMsg,
    SetMetaMsg,
    UpdateProjectMsg
} from "./types/elm";
import {ElmApp} from "./services/elm";
import {AzimuttApi} from "./services/api";
import {Project, ProjectId, ProjectInfoWithContent} from "./types/project";
import {Analytics, LogAnalytics, SplitbeeAnalytics} from "./services/analytics";
import {ErrLogger, LogErrLogger, SentryErrLogger} from "./services/errors";
import {ConsoleLogger} from "./services/logger";
import {loadPolyfills} from "./utils/polyfills";
import {Utils} from "./utils/utils";
import {Supabase} from "./services/supabase";
import {StorageManager} from "./storages/manager";
import {Conf} from "./conf";
import {IndexedDBStorage} from "./storages/indexeddb";
import {LocalStorageStorage} from "./storages/localstorage";
import {InMemoryStorage} from "./storages/inmemory";
import {StorageApi} from "./storages/api";

const env = Utils.getEnv()
const platform = Utils.getPlatform()
const conf = Conf.get(env)
const logger = new ConsoleLogger(env)
const fs = {env, platform, backendUrl: conf.supabase.backendUrl}
const app = ElmApp.init({now: Date.now(), conf: fs}, logger)
const supabase = Supabase.init(conf.supabase).onLogin(user => {
    app.login(user)
    analytics.login(user)
    listProjects()
}, err => app.toast('error', err))
const storage: Promise<StorageApi> = IndexedDBStorage.init(logger).catch(() => LocalStorageStorage.init(logger)).catch(() => new InMemoryStorage())
const store = new StorageManager(supabase, logger)
const skipAnalytics = !!JSON.parse(localStorage.getItem('skip-analytics') || 'false')
const analytics: Analytics = env === 'prod' && !skipAnalytics ? new SplitbeeAnalytics(conf.splitbee) : new LogAnalytics(logger)
const errorTracking: ErrLogger = env === 'prod' ? new SentryErrLogger(conf.sentry) : new LogErrLogger(logger)
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
app.on('Login', msg => supabase.login(msg.info, msg.redirect).then(user => {
    app.login(user)
    analytics.login(user)
}).then(listProjects).catch(logger.warn))
app.on('Logout', _ => supabase.logout().then(() => {
    app.logout()
    analytics.logout()
}).then(listProjects).catch(logger.warn))
app.on('GetProject', getProject)
app.on('ListProjects', listProjects)
app.on('LoadProject', msg => loadProject(msg.id))
app.on('CreateProject', msg => store.createProject(msg.project).then(app.gotProject))
app.on('UpdateProject', msg => updateProject(msg).then(app.gotProject))
app.on('MoveProjectTo', msg => store.moveProjectTo(msg.project, msg.storage).then(app.gotProject).catch(err => app.toast('error', err)))
app.on('GetUser', msg => store.getUser(msg.email).then(user => app.gotUser(msg.email, user)).catch(_ => app.gotUser(msg.email, undefined)))
app.on('UpdateUser', msg => store.updateUser(msg.user).then(_ => {
    app.login(msg.user)
    app.toast('success', 'Profile updated!')
}))
app.on('GetOwners', msg => store.getOwners(msg.project).then(owners => app.gotOwners(msg.project, owners)))
app.on('SetOwners', msg => store.setOwners(msg.project, msg.owners).then(owners => app.gotOwners(msg.project, owners)))
app.on('DownloadFile', msg => Utils.downloadFile(msg.filename, msg.content))
app.on('DropProject', msg => store.dropProject(msg.project).then(_ => app.dropProject(msg.project.id)))
app.on('GetLocalFile', getLocalFile)
app.on('ObserveSizes', observeSizes)
app.on('ListenKeys', listenHotkeys)
app.on('Confetti', msg => Utils.launchConfetti(msg.id))
app.on('ConfettiPride', _ => Utils.launchConfettiPride())
app.on('TrackPage', msg => analytics.trackPage(msg.name))
app.on('TrackEvent', msg => analytics.trackEvent(msg.name, msg.details))
app.on('TrackError', msg => {
    analytics.trackError(msg.name, msg.details)
    errorTracking.trackError(msg.name, msg.details)
})
if (app.noListeners().length > 0) {
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
    if (typeof meta.html === 'string') {
        document.getElementsByTagName('html')[0]?.setAttribute('class', meta.html)
    }
    if (typeof meta.body === 'string') {
        document.getElementsByTagName('body')[0]?.setAttribute('class', meta.body)
    }
}

function getProject(msg: GetProjectMsg) {
    Utils.fetchJson<ProjectInfoWithContent>(`/api/v1/organizations/${msg.organization}/projects/${msg.project}?expand=content`).then(res => {
        if (res.status === 200) {
            if (res.json.storage_kind === 'azimutt') {
                if (typeof res.json.content === 'string') {
                    return app.gotProject(JSON.parse(res.json.content))
                } else {
                    return Promise.reject(`missing content`)
                }
            } else if (res.json.storage_kind === 'local') {
                // TODO: if fail: add message to sync to Azimutt to have the project everywhere
                return storage.then(s => s.loadProject(msg.project)).then(app.gotProject)
            } else {
                return Promise.reject(`unknown storage '${res.json.storage_kind}'`)
            }
        } else if (res.status === 404) {
            app.toast('warning', 'Unregistered project: create an Azimutt account and save it again to keep it. '
                + 'Your data will stay local, only statistics will be shared with Azimutt.')
            return storage.then(s => s.loadProject(msg.project)).then(app.gotProject)
        } else {
            return Promise.reject(`unknown status ${res.status}`)
        }
    }).catch(err => {
        app.gotProject(undefined)
        app.toast('error', `Can't load project: ${err}`)
    })
}

function listProjects() {
    store.listProjects().then(app.loadProjects).catch(err => {
        app.loadProjects([])
        app.toast('error', `Can't list projects: ${err}`)
    })
}

function loadProject(id: ProjectId) {
    store.loadProject(id).then(app.gotProject).catch(err => {
        app.gotProject(undefined)
        app.toast('error', `Can't load project: ${err}`)
    })
}

function updateProject(msg: UpdateProjectMsg): Promise<Project> {
    return store.updateProject(msg.project)
        .then(p => {
            app.toast('success', 'Project saved')
            return p
        })
        .catch(e => {
            let message
            if (typeof e === 'string') {
                message = e
            } else if (e.code === DOMException.QUOTA_EXCEEDED_ERR) {
                message = "Can't save project, storage quota exceeded. Use a smaller schema or clean unused ones."
            } else {
                message = 'Unknown storage error: ' + e.message
            }
            app.toast('error', message)
            const name = 'storage'
            const details = typeof e === 'string' ? {error: e} : {error: e.name, message: e.message}
            analytics.trackError(name, details)
            errorTracking.trackError(name, details)
            return msg.project
        })
}

function getLocalFile(msg: GetLocalFileMsg) {
    const reader = new FileReader()
    reader.onload = (e: any) => app.gotLocalFile(msg, e.target.result)
    reader.readAsText(msg.file as any)
}

const resizeObserver = new ResizeObserver(entries => {
    app.updateSizes(entries.map(entry => {
        const rect = entry.target.getBoundingClientRect() // viewport position & size
        // const sizeCanvas = {width: entry.contentRect.width, height: entry.contentRect.height} // don't change with zoom
        const sizeViewport = {width: rect.width, height: rect.height} // depend on zoom
        return {
            id: entry.target.id,
            position: {clientX: rect.left, clientY: rect.top},
            size: sizeViewport,
            seeds: {dx: Math.random(), dy: Math.random()}
        }
    }))
})

function observeSizes(msg: ObserveSizesMsg) {
    msg.ids.flatMap(Utils.maybeElementById).forEach(elt => resizeObserver.observe(elt))
}

const hotkeys: { [key: string]: (Hotkey & { id: HotkeyId })[] } = {}

// keydown is needed for preventDefault, also can't use Elm Browser.Events.onKeyUp because of it
function isInput(elt: Element) {
    return elt.localName === 'input' || elt.localName === 'textarea'
}

function keydownHotkey(e: KeyboardEvent) {
    const target = e.target as HTMLElement
    const matches = (hotkeys[e.key] || []).filter(hotkey => {
        return (hotkey.ctrl === e.ctrlKey || (Utils.getPlatform() === 'mac' && hotkey.ctrl === e.metaKey)) &&
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
        if (hotkey.preventDefault) e.preventDefault()
        app.gotHotkey(hotkey)
    })
    if (matches.length === 0 && e.key === "Escape" && isInput(target)) target.blur()
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
        analytics.trackEvent(eventName, details)
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
