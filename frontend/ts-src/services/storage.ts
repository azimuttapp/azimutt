import {IndexedDBStorage} from "./storage/indexeddb";
import {LocalStorageStorage} from "./storage/localstorage";
import {InMemoryStorage} from "./storage/inmemory";
import {StorageKind} from "./storage/api";
import {Logger} from "./logger";
import {ProjectId, ProjectJson} from "../types/project";
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

    getProject = (id: ProjectId): Promise<ProjectJson> => {
        this.logger.debug(`storage.getProject(${id})`)
        return this.indexedDb.then(s => s.loadProject(id))
            .catch(_ => this.localStorage.then(s => s.loadProject(id)))
            .catch(_ => this.inMemory.loadProject(id))
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
