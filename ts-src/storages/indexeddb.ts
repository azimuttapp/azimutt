import {ProjectId, ProjectInfoNoStorage, ProjectNoStorage} from "../types/project";
import {projectToInfo, StorageApi, StorageKind} from "./api";
import {LocalStorageStorage} from "./localstorage";
import {Logger} from "../services/logger";

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
        return this.migrateLegacyProjects().then(_ => this.openStore('readonly')).then(store => {
            return new Promise<ProjectInfoNoStorage[]>((resolve, reject) => {
                const projects: ProjectInfoNoStorage[] = []
                store.openCursor().onsuccess = (event: any) => {
                    const cursor = event.target.result
                    if (cursor) {
                        projects.push(projectToInfo(cursor.value))
                        cursor.continue()
                    } else {
                        resolve(projects)
                    }
                }
                (store as any).onerror = (err: any) => reject(`Unable to load projects: ${err}`)
            })
        })
    }
    loadProject = (id: ProjectId): Promise<ProjectNoStorage> =>
        this.migrateLegacyProjects()
            .then(_ => this.openStore('readonly'))
            .then(store => this.getProject(store, id))
            .then(p => p ? p : Promise.reject(`Not found`))
    createProject = (p: ProjectNoStorage): Promise<ProjectNoStorage> => {
        return this.openStore('readwrite').then(store => {
            return this.getProject(store, p.id).then(project => {
                if (project) {
                    return Promise.reject(`Project ${p.id} already exists in ${this.kind}`)
                } else {
                    return reqToPromise(store.add(p)).then(_ => p)
                }
            })
        })
    }
    updateProject = (p: ProjectNoStorage): Promise<ProjectNoStorage> => {
        return this.openStore('readwrite').then(store => {
            return this.getProject(store, p.id).then(project => {
                if (project) {
                    return reqToPromise(store.put(p)).then(_ => p)
                } else {
                    return Promise.reject(`Project ${p.id} doesn't exists in ${this.kind}`)
                }
            })
        })
    }
    dropProject = (id: ProjectId): Promise<void> => {
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
                        .then(project => this.createProject(project))
                        .then(_ => legacyStorage.dropProject(p.id))
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
