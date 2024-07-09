import {successes} from "@azimutt/utils";
import {DatabaseUrl, LegacyProjectId, LegacyProjectJson, SourceId} from "@azimutt/models";
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

    getDbUrl = async (id: SourceId): Promise<DatabaseUrl | undefined> => {
        this.logger.debug(`storage.getDbUrl(${id})`)
        return this.indexedDb.then(s => s.getDbUrl(id))
            .catch(e => e !== 'Not found' ? this.localStorage.then(s => s.getDbUrl(id)) : Promise.reject(e))
            .catch(e => e !== 'Not found' ? this.inMemory.getDbUrl(id) : Promise.reject(e))
            .catch(e => Promise.reject(e === 'Not found' ? `Not found database url ${id}` : e))
    }

    setDbUrl = async (id: SourceId, url: DatabaseUrl): Promise<void> => {
        this.logger.debug(`storage.setDbUrl(${id})`)
        return this.indexedDb.catch(_ => this.localStorage).catch(_ => this.inMemory)
            .then(s => s.setDbUrl(id, url))
            .then(_ => undefined)
    }

    removeDbUrl = (id: SourceId): Promise<void> => {
        this.logger.debug(`storage.removeDbUrl(${id})`)
        return successes([
            this.indexedDb.then(s => s.removeDbUrl(id)),
            this.localStorage.then(s => s.removeDbUrl(id)),
            this.inMemory.removeDbUrl(id)
        ]).then(_ => undefined)
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
