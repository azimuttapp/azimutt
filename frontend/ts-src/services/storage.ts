import {successes} from "@azimutt/utils";
import {LegacyProjectId, LegacyProjectJson} from "@azimutt/models";
import {IndexedDBStorage} from "./storage/indexeddb";
import {LocalStorageStorage} from "./storage/localstorage";
import {InMemoryStorage} from "./storage/inmemory";
import {StorageKind} from "./storage/api";
import {Logger} from "./logger";

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

    getProject = (id: LegacyProjectId): Promise<LegacyProjectJson> => {
        this.logger.debug(`storage.getProject(${id})`)
        return this.indexedDb.then(s => s.loadProject(id))
            .catch(e => e !== 'Not found' ? this.localStorage.then(s => s.loadProject(id)) : Promise.reject(e))
            .catch(e => e !== 'Not found' ? this.inMemory.loadProject(id) : Promise.reject(e))
            .catch(e => Promise.reject(e === 'Not found' ? `Not found project ${id}` : e))
    }

    createProject = (id: LegacyProjectId, p: LegacyProjectJson): Promise<void> => {
        this.logger.debug(`storage.createProject(${id})`, p)
        return this.indexedDb.catch(_ => this.localStorage).catch(_ => this.inMemory)
            .then(s => s.createProject(id, p))
            .then(_ => undefined)
    }

    updateProject = (id: LegacyProjectId, p: LegacyProjectJson): Promise<void> => {
        this.logger.debug(`storage.updateProject(${id})`, p)
        return this.indexedDb.catch(_ => this.localStorage).catch(_ => this.inMemory)
            .then(s => s.updateProject(id, p))
            .then(_ => undefined)
    }

    deleteProject = (id: LegacyProjectId): Promise<void> => {
        this.logger.debug(`storage.deleteProject(${id})`)
        return successes([
            this.indexedDb.then(s => s.deleteProject(id)),
            this.localStorage.then(s => s.deleteProject(id)),
            this.inMemory.deleteProject(id)
        ]).then(_ => undefined)
    }
}
