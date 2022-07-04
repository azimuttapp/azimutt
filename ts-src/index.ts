import {
    GetLocalFileMsg,
    GetRemoteFileMsg,
    Hotkey,
    HotkeyId,
    ListenKeysMsg,
    LoadRemoteProjectMsg,
    ObserveSizesMsg,
    SetMetaMsg,
    UpdateProjectMsg
} from "./types/elm";
import {ElmApp} from "./services/elm";
import {AzimuttApi} from "./services/api";
import {Project, ProjectId} from "./types/project";
import {Analytics, LogAnalytics, SplitbeeAnalytics} from "./services/analytics";
import {ErrLogger, LogErrLogger, SentryErrLogger} from "./services/errors";
import {ConsoleLogger} from "./services/logger";
import {loadPolyfills} from "./utils/polyfills";
import {Utils} from "./utils/utils";
import {Supabase} from "./services/supabase";
import {StorageManager} from "./storages/manager";
import {Conf} from "./conf";
import ForceGraph3D from "3d-force-graph";

const env = Utils.getEnv()
const platform = Utils.getPlatform()
const conf = Conf.get(env)
const logger = new ConsoleLogger(env)
const fs = {env, platform, enableCloud: !!localStorage.getItem('enable-cloud')}
const app = ElmApp.init({now: Date.now(), conf: fs}, logger)
const supabase = Supabase.init(conf.supabase).onLogin(user => {
    app.login(user)
    analytics.login(user)
    listProjects()
}, err => app.toast('error', err))
const store = new StorageManager(supabase, fs.enableCloud, logger)
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
app.on('ListProjects', listProjects)
app.on('LoadProject', msg => loadProject(msg.id))
app.on('LoadRemoteProject', loadRemoteProject)
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
app.on('GetRemoteFile', getRemoteFile)
app.on('ObserveSizes', observeSizes)
app.on('ListenKeys', listenHotkeys)
app.on('Confetti', msg => Utils.launchConfetti(msg.id))
app.on('ConfettiPride', _ => Utils.launchConfettiPride())
app.on('Create3dGraph', msg => { // https://github.com/vasturiano/3d-force-graph
    const elt = document.createElement('div')
    elt.id = '3d-graph'
    elt.style.cssText = 'position:absolute;top:64px;'
    document.body.appendChild(elt)

    const sources = msg.project.sources.filter(s => s.enabled !== false)
    const hideColumns = (msg.project.settings?.hiddenColumns?.list || '').split(',').map(c => new RegExp(c.trim(), 'i'))
    const nodes = sources.flatMap(s => s.tables).map(t => ({
        id: `${t.schema}.${t.table}`,
        name: t.table,
        prefix: t.table.split('_')[0]
    }))
    const links = sources.flatMap(s => s.relations)
        .filter(r => !hideColumns.find(c => c.test(r.src.column) || c.test(r.ref.column)))
        .map(r => ({source: r.src.table, target: r.ref.table}))

    const Graph = ForceGraph3D()(elt)
        .height(window.innerHeight - 64)
        .nodeAutoColorBy('prefix')
        .linkAutoColorBy(d => nodes.find(n => n.id === d.target)?.prefix || 'unknown')
        .linkDirectionalArrowLength(3.5)
        .linkDirectionalArrowRelPos(1)
        .linkDirectionalParticles(10)
        .graphData({nodes, links})
        .onNodeClick((node: any) => { // https://github.com/vasturiano/3d-force-graph/blob/master/example/click-to-focus/index.html
            const distance = 100 // Aim at node from outside it
            const distRatio = 1 + distance / Math.hypot(node.x, node.y, node.z)

            const newPos = node.x || node.y || node.z
                ? {x: node.x * distRatio, y: node.y * distRatio, z: node.z * distRatio}
                : {x: 0, y: 0, z: distance} // special case if node is in (0,0,0)

            Graph.cameraPosition(
                newPos, // new position
                node, // lookAt ({ x, y, z })
                3000  // ms transition duration
            )
        })
})
app.on('Remove3dGraph', _ => document.getElementById('3d-graph')?.remove())
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

function loadRemoteProject(msg: LoadRemoteProjectMsg) {
    fetch(msg.projectUrl)
        .then(res => res.json())
        .then((project: Project) => app.gotProject(project))
        .catch(err => {
            app.loadProjects([])
            app.toast('error', `Can't load remote project: ${err}`)
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
