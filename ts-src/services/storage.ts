import {IndexedDBStorage} from "../storages/indexeddb";
import {LocalStorageStorage} from "../storages/localstorage";
import {InMemoryStorage} from "../storages/inmemory";
import {Logger} from "./logger";
import {StorageKind} from "../storages/api";
import {
    Project,
    ProjectId,
    ProjectInfo,
    ProjectInfoNoStorage,
    ProjectNoStorage,
    ProjectStorage
} from "../types/project";

export class Storage {
    public kind: StorageKind = 'manager'
    private indexedDb: Promise<IndexedDBStorage>
    private localStorage: Promise<LocalStorageStorage>
    private inMemory: InMemoryStorage

    constructor(private logger: Logger) {
        this.indexedDb = IndexedDBStorage.init(logger)
        this.localStorage = LocalStorageStorage.init(logger)
        this.inMemory = new InMemoryStorage()
    }

    listProjects = (): Promise<ProjectInfo[]> => {
        return Promise.all([
            this.indexedDb.then(s => s.listProjects()),
            this.localStorage.then(s => s.listProjects()),
            this.inMemory.listProjects()
        ]).then(projects => projects.flat()).then(browserProjects)
    }

    loadProject = (id: ProjectId): Promise<Project> => {
        return this.indexedDb.then(s => s.loadProject(id))
            .catch(_ => this.localStorage.then(s => s.loadProject(id)))
            .catch(_ => this.inMemory.loadProject(id))
            .then(browserProject)
    }

    createProject = (id: ProjectId, {storage, ...p}: Project): Promise<Project> => {
        return this.indexedDb.catch(_ => this.localStorage).catch(_ => this.inMemory)
            .then(s => s.createProject(id, {...p, createdAt: Date.now(), updatedAt: Date.now()}))
            .then(browserProject)
    }

    updateProject = (id: ProjectId, {storage, ...p}: Project): Promise<Project> => {
        return this.indexedDb.catch(_ => this.localStorage).catch(_ => this.inMemory)
            .then(s => s.updateProject(id, {...p, updatedAt: Date.now()}))
            .then(browserProject)
    }

    deleteProject = (id: ProjectId): Promise<void> => {
        return Promise.all([
            this.indexedDb.then(s => s.deleteProject(id)),
            this.localStorage.then(s => s.deleteProject(id)),
            this.inMemory.deleteProject(id)
        ]).then(_ => undefined).catch(_ => undefined)
    }
}

const browserProjects = (projects: ProjectInfoNoStorage[]): ProjectInfo[] =>
    projects.map(p => ({...p, storage: ProjectStorage.local}))
const browserProject = (p: ProjectNoStorage): Project => ({...p, storage: ProjectStorage.local})
