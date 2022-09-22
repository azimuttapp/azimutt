import {IndexedDBStorage} from "./storage/indexeddb";
import {LocalStorageStorage} from "./storage/localstorage";
import {InMemoryStorage} from "./storage/inmemory";
import {StorageKind} from "./storage/api";
import {Logger} from "./logger";
import {
    computeStats,
    isLegacy,
    ProjectInfoLocalLegacy,
    ProjectJson,
    ProjectJsonLegacy, ProjectStored,
    ProjectId,
    ProjectStorage
} from "../types/project";
import {successes} from "../utils/promise";

export class Storage {
    public kind: StorageKind = 'manager'
    private indexedDb: Promise<IndexedDBStorage>
    private localStorage: Promise<LocalStorageStorage>
    private inMemory: InMemoryStorage

    constructor(private logger: Logger) {
        this.indexedDb = IndexedDBStorage.init(logger.disableDebug())
        this.localStorage = LocalStorageStorage.init(logger.disableDebug())
        this.inMemory = new InMemoryStorage(logger.disableDebug())
    }

    getLegacyProjects = (): Promise<ProjectInfoLocalLegacy[]> => {
        this.logger.debug(`storage.getLegacyProjects()`)
        return successes([
            this.indexedDb.then(s => s.listProjects()),
            this.localStorage.then(s => s.listProjects()),
            this.inMemory.listProjects()
        ]).then(res => filterLegacy(res.flat())).then(projects => projects.map(legacyProjectInfo))
    }

    getLegacyProject = (id: ProjectId): Promise<ProjectJsonLegacy> => {
        this.logger.debug(`storage.getLegacyProject(${id})`)
        return this.indexedDb.then(s => s.loadProject(id))
            .catch(_ => this.localStorage.then(s => s.loadProject(id)))
            .then(toLegacy)
    }

    getProject = (id: ProjectId): Promise<ProjectJson> => {
        this.logger.debug(`storage.getProject(${id})`)
        return this.indexedDb.then(s => s.loadProject(id))
            .catch(_ => this.localStorage.then(s => s.loadProject(id)))
            .catch(_ => this.inMemory.loadProject(id))
            .then(notLegacy)
    }

    createProject = (id: ProjectId, p: ProjectJson): Promise<void> => {
        this.logger.debug(`storage.createProject(${id})`, p)
        return this.indexedDb.catch(_ => this.localStorage).catch(_ => this.inMemory)
            .then(s => s.createProject(id, p))
            .then(_ => undefined)
    }

    updateProject = (id: ProjectId, p: ProjectJson): Promise<void> => {
        this.logger.debug(`storage.updateProject(${id})`, p)
        return this.indexedDb.catch(_ => this.localStorage).catch(_ => this.inMemory)
            .then(s => s.updateProject(id, p))
            .then(_ => undefined)
    }

    deleteProject = (id: ProjectId): Promise<void> => {
        this.logger.debug(`storage.deleteProject(${id})`)
        return successes([
            this.indexedDb.then(s => s.deleteProject(id)),
            this.localStorage.then(s => s.deleteProject(id)),
            this.inMemory.deleteProject(id)
        ]).then(_ => undefined)
    }
}

function filterLegacy(projects: [ProjectId, ProjectStored][]): [ProjectId, ProjectJsonLegacy][] {
    return projects.flatMap(([id, p]) => isLegacy(p) ? [[id, p]] : [])
}

function legacyProjectInfo([id, p]: [ProjectId, ProjectJsonLegacy]): ProjectInfoLocalLegacy {
    return {
        id: id,
        slug: id,
        name: p.name,
        encodingVersion: p.version,
        storage: ProjectStorage.enum.local,
        createdAt: p.createdAt,
        updatedAt: p.updatedAt,
        ...computeStats(p)
    }
}

function notLegacy(p: ProjectStored): Promise<ProjectJson> {
    return isLegacy(p) ? Promise.reject(`Project ${p.name} is legacy!`) : Promise.resolve(p)
}

function toLegacy(p: ProjectStored): Promise<ProjectJsonLegacy> {
    return isLegacy(p) ? Promise.resolve(p) : Promise.reject(`Project ${p.name} is not legacy!`)
}
