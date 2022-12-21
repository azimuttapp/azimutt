import {
    CreateProject,
    CreateProjectTmp,
    DeleteProject,
    GetColumnStats,
    GetLocalFile,
    GetProject,
    GetTableStats,
    Hotkey,
    HotkeyId,
    ListenKeys,
    ObserveSizes,
    ProjectDirty,
    SetMeta,
    UpdateProject,
    UpdateProjectTmp
} from "./types/ports";
import {ElmApp} from "./services/elm";
import {AzimuttApi} from "./services/api";
import {
    buildProjectDraft,
    buildProjectJson,
    buildProjectLegacy,
    buildProjectLocal,
    buildProjectRemote,
    ProjectStorage
} from "./types/project";
import {LogAnalytics, PlausibleAnalytics} from "./services/analytics";
import {LogErrLogger, SentryErrLogger} from "./services/errors";
import {ConsoleLogger} from "./services/logger";
import {loadPolyfills} from "./utils/polyfills";
import {Utils} from "./utils/utils";
import {Storage} from "./services/storage";
import {Conf} from "./conf";
import {Backend} from "./services/backend";
import * as Uuid from "./types/uuid";
import {Platform, ToastLevel, ViewPosition} from "./types/basics";
import {Env, getEnv} from "./utils/env";
import {AnyError, formatError} from "./utils/error";
import * as Json from "./utils/json";
import * as url from "./utils/url";
import {ColumnStats, TableStats} from "./types/stats";

const env = getEnv()
const platform = Utils.getPlatform()
const conf = Conf.get()
const logger = new ConsoleLogger(env)
const flags = {now: Date.now(), conf: {env, platform}}
logger.debug('flags', flags)
const app = ElmApp.init(flags, logger)
const storage = new Storage(logger)
const backend = new Backend(env, logger)
const skipAnalytics = !!Json.parse(localStorage.getItem('skip-analytics') || 'false')
const analytics = env === Env.enum.prod && !skipAnalytics ? new PlausibleAnalytics() : new LogAnalytics(logger)
const errorTracking = env === Env.enum.prod ? new SentryErrLogger(conf.sentry) : new LogErrLogger(logger)
logger.info('Hi there! I hope you are enjoying Azimutt 👍️\n\n' +
    'Did you know you can access your current project in the console?\n' +
    'And even trigger some actions in Azimutt?\n\n' +
    'Just look at `azimutt` variable and perform what you want.\n' +
    'For example, here is how to count the total number of columns in all sources:\n' +
    '  `azimutt.project.sources.flatMap(s => s.tables).flatMap(t => t.columns).length`\n\n' +
    'Use `azimutt.help()` for more details!')

window.azimutt = new AzimuttApi(app, logger)

/* PWA service worker */

if ('serviceWorker' in navigator && env === Env.enum.prod) {
    navigator.serviceWorker.register("/service-worker.js")
    // .then(reg => logger.debug('service-worker registered!', reg))
    // .catch(err => logger.debug('service-worker failed to register!', err))
}

/* Elm ports */

app.on('Click', msg => Utils.getElementById(msg.id).click())
app.on('MouseDown', msg => Utils.getElementById(msg.id).dispatchEvent(new Event('mousedown')))
app.on('Focus', msg => Utils.getElementById(msg.id).focus())
app.on('Blur', msg => Utils.getElementById(msg.id).blur())
app.on('ScrollTo', msg => Utils.maybeElementById(msg.id).forEach(e => e.scrollIntoView(msg.position !== ViewPosition.enum.end)))
app.on('Fullscreen', msg => Utils.fullscreen(msg.id))
app.on('SetMeta', setMeta)
app.on('AutofocusWithin', msg => (Utils.getElementById(msg.id).querySelector<HTMLElement>('[autofocus]'))?.focus())
app.on('Toast', msg => app.toast(msg.level, msg.message))
app.on('GetLegacyProjects', getLegacyProjects)
app.on('GetProject', getProject)
app.on('CreateProjectTmp', createProjectTmp)
app.on('UpdateProjectTmp', updateProjectTmp)
app.on('CreateProject', createProject)
app.on('UpdateProject', updateProject)
// FIXME: app.on('MoveProjectTo', msg => store.moveProjectTo(msg.project, msg.storage).then(app.gotProject).catch(err => app.toast(ToastLevel.enum.error, err)))
app.on('DeleteProject', deleteProject)
app.on('ProjectDirty', projectDirty)
app.on('DownloadFile', msg => Utils.downloadFile(msg.filename, msg.content))
app.on('GetLocalFile', getLocalFile)
app.on('GetTableStats', getTableStats)
app.on('GetColumnStats', getColumnStats)
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
if (app.noListeners().length > 0 && env !== Env.enum.prod) {
    logger.error(`Do not listen to elm events: ${app.noListeners().join(', ')}`)
}

function setMeta(meta: SetMeta) {
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

function getLegacyProjects() {
    storage.getLegacyProjects().then(([errs, p]) => {
        errs.forEach(([id, e]) => reportError(`Can't decode project ${id}`, e))
        app.gotLegacyProjects(p)
        if (p.length > 0) {
            analytics.trackEvent('has-legacy-projects', {count: p.length})
            env === Env.enum.prod && setTimeout(() => alert(`You still have some legacy projects. They won't be supported in 2023. If you don't want to loose them, open and save them before the end of the year.`), 3000)
        }
    }, err => {
        reportError(`Can't list legacy projects`, err)
        app.gotLegacyProjects([])
    })
}

function getProject(msg: GetProject) {
    (msg.project === Uuid.zero ?
            storage.getProject(msg.project).then(p => buildProjectDraft(msg.project, p)) :
            backend.getProject(msg.organization, msg.project).then(res => {
                if (res.storage === ProjectStorage.enum.remote) {
                    return buildProjectRemote(res, res.content)
                } else if (res.storage === ProjectStorage.enum.local) {
                    return storage.getProject(msg.project).then(p => buildProjectLocal(res, p))
                } else {
                    return Promise.reject('Invalid storage')
                }
            }, err => {
                if (err.statusCode === 401) {
                    return storage.getLegacyProject(msg.project).then(p => buildProjectLegacy(msg.project, p), _ => Promise.reject(err))
                } else if (err.statusCode === 404) {
                    return storage.getLegacyProject(msg.project).then(p => {
                        app.toast(ToastLevel.enum.warning, 'Unregistered project: save it again to keep it in you Azimutt account. '
                            + 'Your data will stay local, only statistics will be shared with Azimutt.')
                        return buildProjectLegacy(msg.project, p)
                    })
                } else {
                    return Promise.reject(err)
                }
            })
    ).then(project => {
        app.gotProject(project)
    }, err => {
        if (err.statusCode === 401) {
            window.location.replace(backend.loginUrl(url.relative(window.location)))
        } else {
            reportError(`Can't load project`, err)
            app.gotProject(undefined)
        }
    })
}

function createProjectTmp(msg: CreateProjectTmp): void {
    const json = buildProjectJson(msg.project)
    storage.deleteProject(Uuid.zero)
        .then(_ => storage.createProject(Uuid.zero, json))
        .then(_ => app.gotProject(buildProjectDraft(msg.project.id, json)),
            err => reportError(`Can't save draft project`, err))
}

function updateProjectTmp(msg: UpdateProjectTmp): void {
    const json = buildProjectJson(msg.project)
    storage.updateProject(Uuid.zero, json)
        .then(_ => null, err => reportError(`Can't update draft project`, err))
}

function createProject(msg: CreateProject): void {
    const json = buildProjectJson(msg.project)
    if (msg.storage == ProjectStorage.enum.local) {
        backend.createProjectLocal(msg.organization, json).then(res => {
            return storage.createProject(res.id, json).then(_ => buildProjectLocal(res, json), err => {
                reportError(`Can't save project locally`, err)
                return backend.deleteProject(msg.organization, res.id).then(_ => Promise.reject(err))
            })
        }, err => {
            reportError(`Can't save project to backend`, err)
            return Promise.reject(err)
        }).then(p => {
            // delete previously stored projects: draft and legacy one
            return Promise.all([storage.deleteProject(Uuid.zero), storage.deleteProject(msg.project.id)]).catch(err => {
                reportError(`Can't delete temporary project`, err)
                return Promise.resolve()
            }).then(_ => {
                app.toast(ToastLevel.enum.success, `Project created!`)
                window.history.replaceState("", "", `/${msg.organization}/${p.id}`)
                app.gotProject(p)
            })
        })
    } else if (msg.storage == ProjectStorage.enum.remote) {
        backend.createProjectRemote(msg.organization, json).then(p => {
            // delete previously stored projects: draft and legacy one
            return Promise.all([storage.deleteProject(Uuid.zero), storage.deleteProject(msg.project.id)]).catch(err => {
                reportError(`Can't delete temporary project`, err)
                return Promise.resolve()
            }).then(_ => {
                app.toast(ToastLevel.enum.success, `Project created!`)
                window.history.replaceState("", "", `/${msg.organization}/${p.id}`)
                app.gotProject(buildProjectRemote(p, json))
            })
        }, err => reportError(`Can't save project to backend`, err))
    } else {
        reportError(`Unknown ProjectStorage`, msg.storage)
    }
}

function updateProject(msg: UpdateProject): void {
    const json = buildProjectJson(msg.project)
    if (!msg.project.organization) return reportError('Expecting an organization to update project')
    if (msg.project.storage == ProjectStorage.enum.local) {
        backend.updateProjectLocal(msg.project).then(res => {
            return storage.updateProject(res.id, json).then(_ => {
                app.toast(ToastLevel.enum.success, 'Project saved')
                app.gotProject(buildProjectLocal(res, json))
            }, err => reportError(`Can't update project locally`, err))
        }, err => reportError(`Can't update project to backend`, err))
    } else if (msg.project.storage == ProjectStorage.enum.remote) {
        backend.updateProjectRemote(msg.project).then(res => {
            app.toast(ToastLevel.enum.success, 'Project saved')
            app.gotProject(buildProjectRemote(res, json))
        }, err => reportError(`Can't update project`, err))
    } else {
        reportError(`Unknown ProjectStorage`, msg.project.storage)
    }
}

function deleteProject(msg: DeleteProject): void {
    if (msg.project.organization) {
        backend.deleteProject(msg.project.organization.id, msg.project.id).catch(err => {
            reportError(`Can't delete project in backend`, err)
            return Promise.reject(err)
        }).then(_ => {
            if (msg.project.storage == ProjectStorage.enum.local) {
                return storage.deleteProject(msg.project.id).catch(err => {
                    reportError(`Can't delete project locally`, err)
                    return Promise.reject(err)
                })
            }
        }).then(_ => msg.redirect ? window.location.href = msg.redirect : app.dropProject(msg.project.id))
    } else {
        storage.deleteProject(msg.project.id).catch(err => {
            reportError(`Can't delete project locally`, err)
            return Promise.reject(err)
        }).then(_ => msg.redirect ? window.location.href = msg.redirect : app.dropProject(msg.project.id))
    }
}

// prompt users to save before leave project when not fully saved
window.isDirty = false
window.addEventListener('beforeunload', function (e: BeforeUnloadEvent) {
    if (window.isDirty) {
        const message = 'Your project is not saved, want to leave?'
        e.returnValue = message // Gecko, Trident, Chrome 34+
        return message          // Gecko, WebKit, Chrome <34
    }
})

function projectDirty(msg: ProjectDirty): void {
    window.isDirty = msg.dirty
}

function getLocalFile(msg: GetLocalFile) {
    const reader = new FileReader()
    reader.onload = (e: any) => app.gotLocalFile(msg, e.target.result)
    reader.readAsText(msg.file as any)
}

const tableStatsCache: { [key: string]: TableStats } = {}

function getTableStats(msg: GetTableStats) {
    const key = `${msg.source}-${msg.table}`
    if (tableStatsCache[key]) {
        app.gotTableStats(msg.source, tableStatsCache[key])
    } else {
        backend.getTableStats(msg.database, msg.table).then(
            stats => app.gotTableStats(msg.source, tableStatsCache[key] = stats),
            err => err.statusCode !== 404 && reportError(`Can't get stats for ${msg.table}`, err)
        )
    }
}

const columnStatsCache: { [key: string]: ColumnStats } = {}

function getColumnStats(msg: GetColumnStats) {
    const key = `${msg.source}-${msg.column.table}.${msg.column.column}`
    if (columnStatsCache[key]) {
        app.gotColumnStats(msg.source, columnStatsCache[key])
    } else {
        backend.getColumnStats(msg.database, msg.column).then(
            stats => app.gotColumnStats(msg.source, columnStatsCache[key] = stats),
            err => err.statusCode !== 404 && reportError(`Can't get stats for ${msg.column}`, err)
        )
    }
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

function observeSizes(msg: ObserveSizes) {
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
        return (Utils.getPlatform() === Platform.enum.pc ? hotkey.ctrl === e.ctrlKey : hotkey.ctrl === e.metaKey) &&
            (!hotkey.shift || e.shiftKey) &&
            (hotkey.alt === e.altKey) &&
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

function listenHotkeys(msg: ListenKeys) {
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

function reportError(label: string, error?: AnyError) {
    if (error === undefined) {
        logger.error(label)
        app.toast(ToastLevel.enum.error, label)
    } else {
        logger.error(label, error)
        app.toast(ToastLevel.enum.error, `${label}: ${formatError(error)}`)
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
