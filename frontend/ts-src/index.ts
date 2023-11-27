import * as Sentry from "@sentry/browser";
import {BrowserTracing} from "@sentry/tracing";
import {AnyError, errorToString} from "@azimutt/utils";
import {ColumnStats, DatabaseQueryResults, TableStats} from "@azimutt/database-types";
import {prisma} from "@azimutt/parser-prisma";
import {
    CreateProject,
    CreateProjectTmp,
    DeleteProject,
    GetColumnStats,
    GetDatabaseSchema,
    GetLocalFile,
    GetPrismaSchema,
    GetProject,
    GetTableStats,
    Hotkey,
    HotkeyId,
    ListenKeys,
    ObserveSizes,
    ProjectDirty,
    RunDatabaseQuery,
    SetMeta,
    Track,
    UpdateProject,
    UpdateProjectTmp
} from "./types/ports";
import {ElmApp} from "./services/elm";
import {AzimuttApi} from "./services/api";
import {
    buildProjectDraft,
    buildProjectJson,
    buildProjectLocal,
    buildProjectRemote,
    ProjectStorage
} from "./types/project";
import {ConsoleLogger} from "./services/logger";
import {loadPolyfills} from "./utils/polyfills";
import {Utils} from "./utils/utils";
import {Storage} from "./services/storage";
import {Backend} from "./services/backend";
import * as Uuid from "./types/uuid";
import {HtmlId, Platform, ToastLevel, ViewPosition} from "./types/basics";
import {Env} from "./utils/env";
import * as url from "./utils/url";

const platform = Utils.getPlatform()
const logger = new ConsoleLogger(window.env)
const flags = {now: Date.now(), conf: {env: window.env, platform, desktop: !!window.desktop}}
logger.debug('flags', flags)
const app = ElmApp.init(flags, logger)
const storage = new Storage(logger)
const backend = new Backend(logger)
logger.info('Hi there! I hope you are enjoying Azimutt 👍️\n\n' +
    'Did you know you can access your current project in the console?\n' +
    'And even trigger some actions in Azimutt?\n\n' +
    'Just look at `azimutt` variable and perform what you want.\n' +
    'For example, here is how to count the total number of columns in all sources:\n' +
    '  `azimutt.project.sources.flatMap(s => s.tables).flatMap(t => t.columns).length`\n\n' +
    'Use `azimutt.help()` for more details!')

window.azimutt = new AzimuttApi(app, logger)

/* PWA service worker */

if ('serviceWorker' in navigator && window.env === Env.enum.prod) {
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
app.on('Fullscreen', msg => Utils.fullscreen(msg.id).then(() => app.fitToScreen()))
app.on('SetMeta', setMeta)
app.on('AutofocusWithin', msg => (Utils.getElementById(msg.id).querySelector<HTMLElement>('[autofocus]'))?.focus())
app.on('Toast', msg => app.toast(msg.level, msg.message))
app.on('GetProject', getProject)
app.on('CreateProjectTmp', createProjectTmp)
app.on('UpdateProjectTmp', updateProjectTmp)
app.on('CreateProject', createProject)
app.on('UpdateProject', updateProject)
// FIXME: app.on('MoveProjectTo', msg => store.moveProjectTo(msg.project, msg.storage).then(app.gotProject).catch(err => app.toast(ToastLevel.enum.error, err)))
app.on('DeleteProject', deleteProject)
app.on('ProjectDirty', projectDirty)
app.on('DownloadFile', msg => Utils.downloadFile(msg.filename, msg.content))
app.on('CopyToClipboard', msg => Utils.copyToClipboard(msg.content)
    .then(_ => app.toast(ToastLevel.enum.success, `Content copied to clipboard`))
    .catch(err => app.toast(ToastLevel.enum.warning, `Can't copy to clipboard: ${errorToString(err)}`)))
app.on('GetLocalFile', getLocalFile)
app.on('GetDatabaseSchema', getDatabaseSchema)
app.on('GetTableStats', getTableStats)
app.on('GetColumnStats', getColumnStats)
app.on('RunDatabaseQuery', runDatabaseQuery)
app.on('GetPrismaSchema', getPrismaSchema)
app.on('ObserveSizes', observeSizes)
app.on('ListenKeys', listenHotkeys)
app.on('Confetti', msg => Utils.launchConfetti(msg.id))
app.on('ConfettiPride', _ => Utils.launchConfettiPride())
app.on('Fireworks', _ => Utils.launchFireworks())
app.on('Track', msg => backend.trackEvent(msg.event))
if (app.noListeners().length > 0 && window.env !== Env.enum.prod) {
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

function getProject(msg: GetProject) {
    (msg.project === Uuid.zero ?
            storage.getProject(msg.project).then(p => buildProjectDraft(msg.project, p)) :
            backend.getProject(msg.organization, msg.project, msg.token).then(res => {
                if (res.storage === ProjectStorage.enum.remote) {
                    return buildProjectRemote(res, res.content)
                } else if (res.storage === ProjectStorage.enum.local) {
                    return storage.getProject(msg.project).then(p => buildProjectLocal(res, p))
                } else {
                    return Promise.reject('Invalid storage')
                }
            })
    ).then(project => app.gotProject('load', project), err => {
        if (err.statusCode === 401) {
            window.location.replace(backend.loginUrl(url.relative(window.location)))
        } else {
            reportError(`Can't load project`, err)
            app.gotProject('load', undefined)
        }
    })
}

function createProjectTmp(msg: CreateProjectTmp): void {
    const json = buildProjectJson(msg.project)
    storage.deleteProject(Uuid.zero)
        .then(_ => storage.createProject(Uuid.zero, json))
        .then(_ => app.gotProject('draft', buildProjectDraft(msg.project.id, json)),
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
                app.gotProject('create', p)
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
                app.gotProject('create', buildProjectRemote(p, json))
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
                app.gotProject('update', buildProjectLocal(res, json))
            }, err => reportError(`Can't update project locally`, err))
        }, err => reportError(`Can't update project to backend`, err))
    } else if (msg.project.storage == ProjectStorage.enum.remote) {
        backend.updateProjectRemote(msg.project).then(res => {
            app.toast(ToastLevel.enum.success, 'Project saved')
            app.gotProject('update', buildProjectRemote(res, json))
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
    if (window.isDirty && window.env !== 'dev') {
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

function getDatabaseSchema(msg: GetDatabaseSchema) {
    (window.desktop ?
            window.desktop.getDatabaseSchema(msg.database) :
            backend.getDatabaseSchema(msg.database)
    ).then(
        schema => app.gotDatabaseSchema(schema),
        err => app.gotDatabaseSchemaError(errorToString(err))
    )
}

function getTableStats(msg: GetTableStats) {
    const key = `${msg.source}-${msg.table}`
    if (tableStatsCache[key]) {
        app.gotTableStats(msg.source, tableStatsCache[key])
    } else {
        (window.desktop ?
            window.desktop.getTableStats(msg.database, msg.table) :
            backend.getTableStats(msg.database, msg.table)
        ).then(
            stats => app.gotTableStats(msg.source, tableStatsCache[key] = stats),
            err => app.gotTableStatsError(msg.source, msg.table, errorToString(err))
        )
    }
}

const columnStatsCache: { [key: string]: ColumnStats } = {}

function getColumnStats(msg: GetColumnStats) {
    const key = `${msg.source}-${msg.column.table}.${msg.column.column}`
    if (columnStatsCache[key]) {
        app.gotColumnStats(msg.source, columnStatsCache[key])
    } else {
        (window.desktop ?
            window.desktop.getColumnStats(msg.database, msg.column) :
            backend.getColumnStats(msg.database, msg.column)
        ).then(
            stats => app.gotColumnStats(msg.source, columnStatsCache[key] = stats),
            err => app.gotColumnStatsError(msg.source, msg.column, errorToString(err))
        )
    }
}

function runDatabaseQuery(msg: RunDatabaseQuery) {
    const start = Date.now();
    (window.desktop ?
        window.desktop.runDatabaseQuery(msg.database, msg.query.sql) :
        backend.runDatabaseQuery(msg.database, msg.query.sql)
    ).then(
        (results: DatabaseQueryResults) => app.gotDatabaseQueryResult(msg.context, msg.query, results, start, Date.now()),
        (err: any) => app.gotDatabaseQueryResult(msg.context, msg.query, errorToString(err), start, Date.now())
    )
}

function getPrismaSchema(msg: GetPrismaSchema) {
    prisma.parse(msg.content).then(
        schema => app.gotPrismaSchema(schema),
        err => app.gotPrismaSchemaError(errorToString(err))
    )
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
    msg.ids.forEach(id => {
        const elt = document.getElementById(id)
        elt ? resizeObserver.observe(elt) : observeSizesRetry(id, 20)
    })
}

function observeSizesRetry(id: HtmlId, remainingAttempts: number) {
    if (remainingAttempts > 0) {
        setTimeout(() => {
            const elt = document.getElementById(id)
            elt ? resizeObserver.observe(elt) : observeSizesRetry(id, remainingAttempts - 1)
        }, 200)
    }
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
        app.toast(ToastLevel.enum.error, `${label}: ${errorToString(error)}`)
    }
}


// listen at every click to handle tracking events
// MUST stay sync with frontend/src/Libs/Html/Attributes.elm:123#track
function trackClick(e: MouseEvent) {
    const target = e.target as HTMLElement
    const tracked = Utils.findParent(target, e => !!e.getAttribute('data-track-event'))
    if (tracked) {
        const name = tracked.getAttribute('data-track-event') || 'click'
        const trackDetails: { [key: string]: string } = {label: (tracked.textContent || '').trim()}
        const attrs = tracked.attributes
        for (let i = 0; i < attrs.length; i++) {
            const attr = attrs[i]
            if (attr.name.startsWith('data-track-event-')) {
                trackDetails[attr.name.replace('data-track-event-', '')] = attr.value
            }
        }
        const {organization, project, ...details} = trackDetails
        backend.trackEvent({name, details, organization, project})
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

if (window.sentry_frontend_dsn) {
    Sentry.init({
        dsn: window.sentry_frontend_dsn,
        integrations: [new BrowserTracing()],
        tracesSampleRate: 1.0,
        ignoreErrors: ['Non-Error promise rejection captured']
    })
}

loadPolyfills()
