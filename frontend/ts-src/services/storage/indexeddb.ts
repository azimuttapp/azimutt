import {ProjectId, ProjectJson} from "../../types/project";
import {StorageApi, StorageKind} from "./api";
import {Logger} from "../logger";
import * as Zod from "../../utils/zod";

export class IndexedDBStorage implements StorageApi {
    static databaseName = 'azimutt'
    static databaseVersion = 1
    static dbProjects = 'projects'

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
            }
        }) : Promise.reject('indexedDB not available')
    }

    public kind: StorageKind = 'indexedDb'

    constructor(private db: IDBDatabase, private logger: Logger) {
    }

    loadProject = (id: ProjectId): Promise<ProjectJson> => {
        this.logger.debug(`indexedDb.loadProject(${id})`)
        return this.openStore('readonly')
            .then(store => this.getProject(store, id))
            .then(p => p ? p : Promise.reject(`Not found`))
    }
    createProject = (id: ProjectId, p: ProjectJson): Promise<ProjectJson> => {
        this.logger.debug(`indexedDb.createProject(${id})`, p)
        return this.openStore('readwrite').then(store => {
            return this.getProject(store, id).then(project => {
                if (project) {
                    return Promise.reject(`Project ${id} already exists in ${this.kind}`)
                } else {
                    return reqToPromise(store.add({...Zod.validate(p, ProjectJson, 'ProjectJson'), id})).then(_ => p)
                }
            })
        })
    }
    updateProject = (id: ProjectId, p: ProjectJson): Promise<ProjectJson> => {
        this.logger.debug(`indexedDb.updateProject(${id})`, p)
        return this.openStore('readwrite').then(store => {
            return this.getProject(store, id).then(project => {
                if (project) {
                    return reqToPromise(store.put({...Zod.validate(p, ProjectJson, 'ProjectJson'), id})).then(_ => p)
                } else {
                    return Promise.reject(`Project ${id} doesn't exists in ${this.kind}`)
                }
            })
        })
    }
    deleteProject = (id: ProjectId): Promise<void> => {
        this.logger.debug(`indexedDb.deleteProject(${id})`)
        return this.openStore('readwrite').then(store => reqToPromise(store.delete(id)))
    }

    private openStore(mode: IDBTransactionMode): Promise<IDBObjectStore> {
        return new Promise<IDBObjectStore>(resolve => resolve(this.db.transaction(IndexedDBStorage.dbProjects, mode).objectStore(IndexedDBStorage.dbProjects)))
    }

    private getProject(store: IDBObjectStore, id: ProjectId): Promise<ProjectJson | undefined> {
        return new Promise<ProjectJson | undefined>((resolve, reject) => {
            store.get(id).onsuccess = (event: any) => resolve(Zod.validate(removeId(event.target.result), ProjectJson.optional(), 'ProjectJson?'));
            (store as any).onerror = (err: any) => reject(`Unable to load project: ${err}`)
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
