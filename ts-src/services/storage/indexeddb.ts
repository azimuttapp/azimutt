import {ProjectId, ProjectInfoNoStorage, ProjectNoStorage} from "../../types/project";
import {projectToInfo, StorageApi, StorageKind} from "./api";
import {LocalStorageStorage} from "./localstorage";
import {Logger} from "../logger";

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

    private migrated = false
    public kind: StorageKind = 'indexedDb'

    constructor(private db: IDBDatabase, private logger: Logger) {
    }

    listProjects = (): Promise<ProjectInfoNoStorage[]> => {
        console.log(`indexedDb.listProjects()`)
        return this.migrateLegacyProjects().then(_ => this.openStore('readonly')).then(store => {
            return new Promise<ProjectInfoNoStorage[]>((resolve, reject) => {
                const projects: ProjectInfoNoStorage[] = []
                store.openCursor().onsuccess = (event: any) => {
                    const cursor = event.target.result
                    if (cursor) {
                        projects.push(projectToInfo(cursor.key, cursor.value))
                        cursor.continue()
                    } else {
                        resolve(projects)
                    }
                }
                (store as any).onerror = (err: any) => reject(`Unable to load projects: ${err}`)
            })
        })
    }
    loadProject = (id: ProjectId): Promise<ProjectNoStorage> => {
        console.log(`indexedDb.loadProject(${id})`)
        return this.migrateLegacyProjects()
            .then(_ => this.openStore('readonly'))
            .then(store => this.getProject(store, id))
            .then(p => p ? p : Promise.reject(`Not found`))
    }
    createProject = (id: ProjectId, p: ProjectNoStorage): Promise<ProjectNoStorage> => {
        console.log(`indexedDb.createProject(${id})`, p)
        return this.openStore('readwrite').then(store => {
            return this.getProject(store, id).then(project => {
                if (project) {
                    return Promise.reject(`Project ${id} already exists in ${this.kind}`)
                } else {
                    return reqToPromise(store.add({...p, id})).then(_ => p)
                }
            })
        })
    }
    updateProject = (id: ProjectId, p: ProjectNoStorage): Promise<ProjectNoStorage> => {
        console.log(`indexedDb.updateProject(${id})`, p)
        return this.openStore('readwrite').then(store => {
            return this.getProject(store, id).then(project => {
                if (project) {
                    return reqToPromise(store.put(p)).then(_ => p)
                } else {
                    return Promise.reject(`Project ${id} doesn't exists in ${this.kind}`)
                }
            })
        })
    }
    deleteProject = (id: ProjectId): Promise<void> => {
        console.log(`indexedDb.deleteProject(${id})`)
        return this.openStore('readwrite').then(store => reqToPromise(store.delete(id)))
    }

    private openStore(mode: IDBTransactionMode): Promise<IDBObjectStore> {
        return new Promise<IDBObjectStore>(resolve => resolve(this.db.transaction(IndexedDBStorage.dbProjects, mode).objectStore(IndexedDBStorage.dbProjects)))
    }

    private getProject(store: IDBObjectStore, id: ProjectId): Promise<ProjectNoStorage | undefined> {
        return new Promise<ProjectNoStorage>((resolve, reject) => {
            store.get(id).onsuccess = (event: any) => resolve(event.target.result);
            (store as any).onerror = (err: any) => reject(`Unable to load project: ${err}`)
        })
    }

    private migrateLegacyProjects = (): Promise<void> => {
        if (this.migrated) return Promise.resolve()
        this.migrated = true
        return LocalStorageStorage.init(this.logger).then(legacyStorage =>
            legacyStorage.listProjects().then(projectInfos =>
                Promise.all(projectInfos.map(p =>
                    legacyStorage.loadProject(p.id)
                        .then(project => this.createProject(p.id, project))
                        .then(_ => legacyStorage.deleteProject(p.id))
                )).then(_ => undefined)
            )
        )
    }
}

function reqToPromise<T>(req: IDBRequest<T>): Promise<T> {
    return new Promise<T>((resolve, reject) => {
        req.onerror = _ => reject(req.error)
        req.onsuccess = _ => resolve(req.result)
    })
}
