import * as Sentry from "@sentry/browser";
import {BrowserTracing} from "@sentry/tracing";
import {AnyError, errorToString} from "@azimutt/utils";
import {
    attributePathFromId,
    AttributeRef,
    columnStatsToLegacy,
    databaseFromLegacy,
    databaseToLegacy,
    DatabaseUrl,
    entityRefFromId,
    legacyBuildProjectDraft,
    legacyBuildProjectJson,
    legacyBuildProjectLocal,
    legacyBuildProjectRemote,
    LegacyColumnStats,
    LegacyDatabase,
    LegacyDatabaseConnection,
    legacyDatabaseJsonFormat,
    LegacyDatabaseQueryResults,
    LegacyProject,
    LegacyProjectStorage,
    LegacyTableStats,
    OpenAIConnector,
    ParserError,
    ProjectId,
    queryResultsToLegacy,
    SourceId,
    sourceToDatabase,
    SqlStatement,
    tableStatsToLegacy,
    textToSql
} from "@azimutt/models";
import {generateAml, parseAml} from "@azimutt/aml";
import {parsePrisma} from "@azimutt/parser-prisma";
import {Dialect, HtmlId, Platform, ToastLevel, ViewPosition} from "./types/basics";
import * as Uuid from "./types/uuid";
import {
    CreateProject,
    CreateProjectTmp,
    DeleteProject,
    DeleteSource,
    ElmFlags,
    GetAmlSchema,
    GetCode,
    GetColumnStats,
    GetDatabaseSchema,
    GetLocalFile,
    GetPrismaSchema,
    GetProject,
    GetTableStats,
    Hotkey,
    HotkeyId,
    ListenKeys,
    LlmGenerateSql,
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
import {ConsoleLogger} from "./services/logger";
import {Storage} from "./services/storage";
import {Backend} from "./services/backend";
import {aesDecrypt, aesEncrypt, base64Decode, base64Valid, isPrintable} from "./utils/crypto";
import {Env} from "./utils/env";
import {loadPolyfills} from "./utils/polyfills";
import * as url from "./utils/url";
import {Utils} from "./utils/utils";
// import {loadIntlDate} from "./components/intl-date";
// import {loadAzEditor} from "./components/az-editor";
// import {loadAmlEditor} from "./components/aml-editor";

// loadIntlDate() // should be before the Elm init
// loadAzEditor() // should be before the Elm init
// loadAmlEditor() // should be before the Elm init
const platform = Utils.getPlatform()
const logger = new ConsoleLogger(window.env)
const flags: ElmFlags = {now: Date.now(), conf: {env: window.env, platform, role: window.role, desktop: !!window.desktop}, params: buildFlagParams()}
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
app.on('DeleteSource', deleteSource)
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
app.on('GetAmlSchema', getAmlSchema)
app.on('GetPrismaSchema', getPrismaSchema)
app.on('GetCode', getCode)
app.on('ObserveSizes', observeSizes)
app.on('LlmGenerateSql', llmGenerateSql)
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

function buildFlagParams(): [string, string][] {
    const hash = url.hash(window.location.hash)
    return Object.entries(Object.assign(
        url.queryParams(window.location.search),
        window.params,
        hash ? {database: hash} : {}
    )).map(([key, value]) => {
        value = url.uriComponentEncoded(value) ? decodeURIComponent(value) : value
        value = base64Valid(value) && isPrintable(base64Decode(value)) ? base64Decode(value) : value
        return [key, value]
    })
}

function getProject(msg: GetProject) {
    (msg.project === Uuid.zero ?
            storage.getProject(msg.project).then(p => legacyBuildProjectDraft(msg.project, p)) :
            backend.getProject(msg.organization, msg.project, msg.token).then(res => {
                if (res.storage === LegacyProjectStorage.enum.remote) {
                    return legacyBuildProjectRemote(res, res.content)
                } else if (res.storage === LegacyProjectStorage.enum.local) {
                    return storage.getProject(msg.project).then(p => legacyBuildProjectLocal(res, p))
                } else {
                    return Promise.reject('Invalid storage')
                }
            })
    ).then(res => loadProject(res).then(p => app.gotProject('load', p)), err => {
        if (err.statusCode === 401) {
            window.location.replace(backend.loginUrl(url.relative(window.location)))
        } else {
            reportError(`Can't load project`, err)
            app.gotProject('load', undefined)
        }
    })
}

async function createProjectTmp(msg: CreateProjectTmp): Promise<void> {
    const project = await saveProject(msg.project)
    const json = legacyBuildProjectJson(project)
    storage.deleteProject(Uuid.zero)
        .then(_ => storage.createProject(Uuid.zero, json))
        .then(_ => loadProject(legacyBuildProjectDraft(project.id, json)).then(p => app.gotProject('draft', p)),
            err => reportError(`Can't save draft project`, err))
}

async function updateProjectTmp(msg: UpdateProjectTmp): Promise<void> {
    const project = await saveProject(msg.project)
    const json = legacyBuildProjectJson(project)
    storage.updateProject(Uuid.zero, json)
        .then(_ => null, err => reportError(`Can't update draft project`, err))
}

async function createProject(msg: CreateProject): Promise<void> {
    const project = await saveProject(msg.project)
    const json = legacyBuildProjectJson(project)
    if (msg.storage == LegacyProjectStorage.enum.local) {
        backend.createProjectLocal(msg.organization, json).then(res => {
            return storage.createProject(res.id, json).then(_ => legacyBuildProjectLocal(res, json), err => {
                reportError(`Can't save project locally`, err)
                return backend.deleteProject(msg.organization, res.id).then(_ => Promise.reject(err))
            })
        }, err => {
            reportError(`Can't save project to backend`, err)
            return Promise.reject(err)
        }).then(res => {
            // delete previously stored projects: draft and legacy one
            return Promise.all([storage.deleteProject(Uuid.zero), storage.deleteProject(project.id)]).catch(err => {
                reportError(`Can't delete temporary project`, err)
                return Promise.resolve()
            }).then(_ => {
                app.toast(ToastLevel.enum.success, `Project created!`)
                window.history.replaceState("", "", `/${msg.organization}/${res.id}`)
                loadProject(res).then(p => app.gotProject('create', p))
            })
        })
    } else if (msg.storage == LegacyProjectStorage.enum.remote) {
        backend.createProjectRemote(msg.organization, json).then(res => {
            // delete previously stored projects: draft and legacy one
            return Promise.all([storage.deleteProject(Uuid.zero), storage.deleteProject(project.id)]).catch(err => {
                reportError(`Can't delete temporary project`, err)
                return Promise.resolve()
            }).then(_ => {
                app.toast(ToastLevel.enum.success, `Project created!`)
                window.history.replaceState("", "", `/${msg.organization}/${res.id}`)
                loadProject(legacyBuildProjectRemote(res, json)).then(p => app.gotProject('create', p))
            })
        }, err => reportError(`Can't save project to backend`, err))
    } else {
        reportError(`Unknown ProjectStorage`, msg.storage)
    }
}

async function updateProject(msg: UpdateProject): Promise<void> {
    const project = await saveProject(msg.project)
    const json = legacyBuildProjectJson(project)
    if (!project.organization) return reportError('Expecting an organization to update project')
    if (project.storage == LegacyProjectStorage.enum.local) {
        backend.updateProjectLocal(project).then(res => {
            return storage.updateProject(res.id, json).then(_ => {
                app.toast(ToastLevel.enum.success, 'Project saved')
                loadProject(legacyBuildProjectLocal(res, json)).then(p => app.gotProject('update', p))
            }, err => reportError(`Can't update project locally`, err))
        }, err => reportError(`Can't update project to backend`, err))
    } else if (project.storage == LegacyProjectStorage.enum.remote) {
        backend.updateProjectRemote(project).then(res => {
            app.toast(ToastLevel.enum.success, 'Project saved')
            loadProject(legacyBuildProjectRemote(res, json)).then(p => app.gotProject('update', p))
        }, err => {
            reportError(`Can't update project`, err)
            app.gotProject('update', undefined)
        })
    } else {
        reportError(`Unknown ProjectStorage`, project.storage)
    }
}

function deleteProject(msg: DeleteProject): void {
    if (msg.project.organization) {
        backend.deleteProject(msg.project.organization.id, msg.project.id).catch(err => {
            reportError(`Can't delete project in backend`, err)
            return Promise.reject(err)
        }).then(_ => {
            if (msg.project.storage == LegacyProjectStorage.enum.local) {
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

async function deleteSource(msg: DeleteSource): Promise<void> {
    delete dbUrlsInMemory[msg.source]
    await storage.removeDbUrl(msg.source)
}

const dbUrlsInMemory: { [key: SourceId]: DatabaseUrl } = {}
const dbUrlIsCrypted = (url: DatabaseUrl): boolean => base64Valid(url)
const dbUrlEncrypt = (project: ProjectId, url: DatabaseUrl): Promise<DatabaseUrl> =>
    dbUrlIsCrypted(url) ? Promise.resolve(url) : aesEncrypt(project.replaceAll('-', ''), url)
const dbUrlDecrypt = (project: ProjectId, url: DatabaseUrl): Promise<DatabaseUrl | undefined> => {
    if (dbUrlIsCrypted(url)) {
        return aesDecrypt(project.replaceAll('-', ''), url)
            .catch(_ => aesDecrypt('00000000-0000-0000-0000-000000000000'.replaceAll('-', ''), url)) // if saved from draft project
            .catch(_ => undefined)
    } else {
        return Promise.resolve(url)
    }
}

async function loadProject(project: LegacyProject): Promise<LegacyProject> {
    const getUrl = async (source: SourceId, kind: LegacyDatabaseConnection): Promise<DatabaseUrl | undefined> => {
        switch (kind.storage) {
            case 'memory': return dbUrlsInMemory[source]
            case 'browser': return await storage.getDbUrl(source)
            case 'project': return kind.url
            default: return kind.url
        }
    }
    const sources = await Promise.all(project.sources.map(async s => {
        if (s.kind.kind === 'DatabaseConnection') {
            const url: DatabaseUrl | undefined = await getUrl(s.id, s.kind)
            return url ? {...s, kind: {...s.kind, url: await dbUrlDecrypt(project.id, url)}} : s
        } else {
            return s
        }
    }))
    return {...project, sources}
}

async function saveProject(project: LegacyProject): Promise<LegacyProject> {
    const sources = await Promise.all(project.sources.map(async s => {
        if (s.kind.kind === 'DatabaseConnection') {
            const {url, ...kind} = s.kind
            delete dbUrlsInMemory[s.id]
            await storage.removeDbUrl(s.id)
            switch (s.kind.storage) {
                case 'memory':
                    url && (dbUrlsInMemory[s.id] = await dbUrlEncrypt(project.id, url))
                    return {...s, kind}
                case 'browser':
                    url && await storage.setDbUrl(s.id, await dbUrlEncrypt(project.id, url))
                    return {...s, kind}
                case 'project':
                    return {...s, kind: {...kind, url: url ? await dbUrlEncrypt(project.id, url) : undefined}}
                default:
                    return s
            }
        } else {
            return s
        }
    }))
    return {...project, sources}
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

const tableStatsCache: { [key: string]: LegacyTableStats } = {}

function getDatabaseSchema(msg: GetDatabaseSchema) {
    (window.desktop ?
        window.desktop.getSchema(msg.database).then(databaseToLegacy) :
        backend.getDatabaseSchema(msg.database)
    ).then(
        (schema: LegacyDatabase) => app.gotDatabaseSchema(schema),
        (err: any) => app.gotDatabaseSchemaError(errorToString(err))
    )
}

function getTableStats(msg: GetTableStats) {
    const key = `${msg.source}-${msg.table}`
    if (tableStatsCache[key]) {
        app.gotTableStats(msg.source, tableStatsCache[key])
    } else {
        const entityRef = entityRefFromId(msg.table);
        (window.desktop ?
            window.desktop.getEntityStats(msg.database, entityRef).then(tableStatsToLegacy) :
            backend.getTableStats(msg.database, entityRef)
        ).then(
            (stats: LegacyTableStats) => app.gotTableStats(msg.source, tableStatsCache[key] = stats),
            (err: any) => app.gotTableStatsError(msg.source, msg.table, errorToString(err))
        )
    }
}

const columnStatsCache: { [key: string]: LegacyColumnStats } = {}

function getColumnStats(msg: GetColumnStats) {
    const key = `${msg.source}-${msg.column.table}.${msg.column.column}`
    if (columnStatsCache[key]) {
        app.gotColumnStats(msg.source, columnStatsCache[key])
    } else {
        const attributeRef: AttributeRef = {...entityRefFromId(msg.column.table), attribute: attributePathFromId(msg.column.column)};
        (window.desktop ?
            window.desktop.getAttributeStats(msg.database, attributeRef).then(columnStatsToLegacy) :
            backend.getColumnStats(msg.database, attributeRef)
        ).then(
            (stats: LegacyColumnStats) => app.gotColumnStats(msg.source, columnStatsCache[key] = stats),
            (err: any) => app.gotColumnStatsError(msg.source, msg.column, errorToString(err))
        )
    }
}

function runDatabaseQuery(msg: RunDatabaseQuery) {
    const start = Date.now();
    (window.desktop ?
        window.desktop.execute(msg.database, msg.query.sql, []).then(queryResultsToLegacy) :
        backend.runDatabaseQuery(msg.database, msg.query.sql)
    ).then(
        (results: LegacyDatabaseQueryResults) => app.gotDatabaseQueryResult(msg.context, msg.source, msg.query, results, start, Date.now()),
        (err: any) => app.gotDatabaseQueryResult(msg.context, msg.source, msg.query, errorToString(err), start, Date.now())
    )
}

function getAmlSchema(msg: GetAmlSchema) {
    const res = parseAml(msg.content).map(databaseToLegacy)
    app.gotAmlSchema(msg.source, msg.content.length, res.result, res.errors || [])
}

function getPrismaSchema(msg: GetPrismaSchema) {
    parsePrisma(msg.content).map(databaseToLegacy).fold(
        (schema: LegacyDatabase) => app.gotPrismaSchema(schema),
        (errors: ParserError[]) => app.gotPrismaSchemaError(errors.map(errorToString).join(', '))
    )
}

function getCode(msg: GetCode) {
    let content = `Unsupported dialect ${msg.dialect}`
    if (msg.dialect === Dialect.enum.AML) {
        content = generateAml(databaseFromLegacy(msg.schema))
    } else if (msg.dialect === Dialect.enum.JSON) {
        content = legacyDatabaseJsonFormat(msg.schema)
    }
    app.gotCode(msg.dialect, content)
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

function llmGenerateSql(msg: LlmGenerateSql) {
    const llm = new OpenAIConnector({apiKey: msg.apiKey, model: msg.model})
    textToSql(llm, msg.dialect, msg.prompt, sourceToDatabase(msg.source)).then(
        (query: SqlStatement) => app.gotLlmSqlGenerated(query),
        (err: any) => app.gotLlmSqlGeneratedError(errorToString(err))
    )
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
