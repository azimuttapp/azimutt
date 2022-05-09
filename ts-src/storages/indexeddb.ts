import {Project} from "../types/project";
import {StorageApi, StorageKind} from "./api";
import {LocalStorageStorage} from "./localstorage";

export class IndexedDBStorage implements StorageApi {
    static databaseName = 'azimutt'
    static databaseVersion = 1
    static dbProjects = 'projects'
    static init(): Promise<IndexedDBStorage> {
        return window.indexedDB ? new Promise((resolve, reject) => {
            const openRequest = window.indexedDB.open(IndexedDBStorage.databaseName, IndexedDBStorage.databaseVersion)
            openRequest.onerror = _ => reject('Unable to open indexedDB')
            openRequest.onsuccess = (event: any) => resolve(new IndexedDBStorage(event.target.result))
            openRequest.onupgradeneeded = (event: any) => {
                const db = event.target.result
                if (!db.objectStoreNames.contains(IndexedDBStorage.dbProjects)) {
                    db.createObjectStore(IndexedDBStorage.dbProjects, {keyPath: 'id'})
                }
            }
        }) : Promise.reject('indexedDB not available')
    }

    public kind: StorageKind = 'indexedDb'

    constructor(private db: IDBDatabase) {
    }

    loadProjects = (): Promise<Project[]> => {
        return this.openStore('readonly').then(store => {
            return new Promise((resolve, reject) => {
                let projects: Project[] = []
                store.openCursor().onsuccess = (event: any) => {
                    const cursor = event.target.result
                    if (cursor) {
                        projects.push(cursor.value)
                        cursor.continue()
                    } else {
                        LocalStorageStorage.init().then(legacyStorage =>
                            legacyStorage.loadProjects().then(localStorageProjects =>
                                Promise.all(localStorageProjects.map(p => Promise.all([legacyStorage.dropProject(p), this.saveProject(p)])))
                                    .then(_ => resolve(projects.concat(localStorageProjects)))
                            )
                        ).catch(reject)
                    }
                }
            })
        }
        )
    }
    saveProject = (p: Project): Promise<void> => {
        return this.openStore('readwrite').then(store => {
            const now = Date.now()
            p.updatedAt = now
            if (!store.get(p.id)) {
                p.createdAt = now
                return reqToPromise(store.add(p)).then(_ => undefined)
            } else {
                return reqToPromise(store.put(p)).then(_ => undefined)
            }
        })
    }
    dropProject = (p: Project): Promise<void> => {
        return this.openStore('readwrite').then(store => reqToPromise(store.delete(p.id)))
    }

    private openStore(mode: IDBTransactionMode): Promise<IDBObjectStore> {
        return new Promise<IDBObjectStore>(resolve => resolve(this.db.transaction(IndexedDBStorage.dbProjects, mode).objectStore(IndexedDBStorage.dbProjects)))
    }
}

function reqToPromise<T>(req: IDBRequest<T>): Promise<T> {
    return new Promise((resolve, reject) => {
        req.onerror = _ => reject(req.error)
        req.onsuccess = _ => resolve(req.result)
    })
}
