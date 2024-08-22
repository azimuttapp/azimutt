import {DatabaseUrl, LegacyProjectId, LegacyProjectJson, SourceId, zodParse} from "@azimutt/models";
import {StorageApi, StorageKind} from "./api";
import {Logger} from "../logger";

export class IndexedDBStorage implements StorageApi {
    static databaseName = 'azimutt'
    static databaseVersion = 2
    static dbProjects = 'projects'
    static dbConnections = 'connections'

    static init(logger: Logger): Promise<IndexedDBStorage> {
        return window.indexedDB ? new Promise<IndexedDBStorage>((resolve, reject) => {
            const openRequest = window.indexedDB.open(IndexedDBStorage.databaseName, IndexedDBStorage.databaseVersion)
            openRequest.onerror = _ => reject('Unable to open indexedDB')
            openRequest.onsuccess = (event: any) => resolve(new IndexedDBStorage(event.target.result, logger))
            openRequest.onupgradeneeded = (event: any) => {
                const db = event.target.result
                if (!db.objectStoreNames.contains(IndexedDBStorage.dbProjects)) {
                    db.createObjectStore(IndexedDBStorage.dbProjects, {keyPath: 'id'})
                }
                if (!db.objectStoreNames.contains(IndexedDBStorage.dbConnections)) {
                    db.createObjectStore(IndexedDBStorage.dbConnections, {keyPath: 'id'})
                }
            }
        }) : Promise.reject('indexedDB not available')
    }

    public kind: StorageKind = 'indexedDb'

    constructor(private db: IDBDatabase, private logger: Logger) {
    }

    getDbUrl = (id: SourceId): Promise<DatabaseUrl | undefined> => {
        this.logger.debug(`indexedDb.getDbUrl(${id})`)
        return this.openStore(IndexedDBStorage.dbConnections, 'readonly')
            .then(store => this.fetchDbUrl(store, id))
    }

    setDbUrl = (id: SourceId, url: DatabaseUrl): Promise<void> => {
        this.logger.debug(`indexedDb.setDbUrl(${id})`)
        return this.openStore(IndexedDBStorage.dbConnections, 'readwrite')
            .then(store => reqToPromise(store.add({id, url})))
            .then(_ => undefined)
    }

    removeDbUrl = (id: SourceId): Promise<void> => {
        this.logger.debug(`indexedDb.removeDbUrl(${id})`)
        return this.openStore(IndexedDBStorage.dbConnections, 'readwrite').then(store => reqToPromise(store.delete(id)))
    }

    loadProject = (id: LegacyProjectId): Promise<LegacyProjectJson> => {
        this.logger.debug(`indexedDb.loadProject(${id})`)
        return this.openStore(IndexedDBStorage.dbProjects, 'readonly')
            .then(store => this.fetchProject(store, id))
            .then(p => p ? p : Promise.reject(`Not found`))
    }
    createProject = (id: LegacyProjectId, p: LegacyProjectJson): Promise<LegacyProjectJson> => {
        this.logger.debug(`indexedDb.createProject(${id})`, p)
        return this.openStore(IndexedDBStorage.dbProjects, 'readwrite').then(store => {
            return this.fetchProject(store, id).then(project => {
                if (project) {
                    return Promise.reject(`Project ${id} already exists in ${this.kind}`)
                } else {
                    return zodParse(LegacyProjectJson)(p).toPromise()
                        .then(res => reqToPromise(store.add({...res, id})))
                        .then(_ => p)
                }
            })
        })
    }
    updateProject = (id: LegacyProjectId, p: LegacyProjectJson): Promise<LegacyProjectJson> => {
        this.logger.debug(`indexedDb.updateProject(${id})`, p)
        return this.openStore(IndexedDBStorage.dbProjects, 'readwrite').then(store => {
            return this.fetchProject(store, id).then(project => {
                if (project) {
                    return zodParse(LegacyProjectJson)(p).toPromise()
                        .then(res => reqToPromise(store.put({...res, id})))
                        .then(_ => p)
                } else {
                    return Promise.reject(`Project ${id} doesn't exists in ${this.kind}`)
                }
            })
        })
    }
    deleteProject = (id: LegacyProjectId): Promise<void> => {
        this.logger.debug(`indexedDb.deleteProject(${id})`)
        return this.openStore(IndexedDBStorage.dbProjects, 'readwrite').then(store => reqToPromise(store.delete(id)))
    }

    private openStore(store: string, mode: IDBTransactionMode): Promise<IDBObjectStore> {
        return new Promise<IDBObjectStore>(resolve => resolve(this.db.transaction(store, mode).objectStore(store)))
    }

    private fetchProject(store: IDBObjectStore, id: LegacyProjectId): Promise<LegacyProjectJson | undefined> {
        return new Promise<LegacyProjectJson | undefined>((resolve, reject) => {
            store.get(id).onsuccess = (event: any) => zodParse(LegacyProjectJson.optional())(removeId(event.target.result)).fold(resolve, reject);
            (store as any).onerror = (err: any) => reject(`Unable to load project: ${err}`)
        })
    }

    private fetchDbUrl(store: IDBObjectStore, id: SourceId): Promise<DatabaseUrl | undefined> {
        return new Promise<DatabaseUrl | undefined>((resolve, reject) => {
            store.get(id).onsuccess = (event: any) => resolve(event.target.result?.url);
            (store as any).onerror = (err: any) => reject(`Unable to load database url: ${err}`)
        })
    }
}

function removeId(value: any & {id: any}): any {
    if (typeof value === 'object' && value !== null) {
        const {id, ...rest} = value
        return rest
    } else {
        return value
    }
}

function reqToPromise<T>(req: IDBRequest<T>): Promise<T> {
    return new Promise<T>((resolve, reject) => {
        req.onerror = _ => reject(req.error)
        req.onsuccess = _ => resolve(req.result)
    })
}
