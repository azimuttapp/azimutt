import {Project, ProjectId, ProjectInfo} from "../types/project";
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

    listProjects = (): Promise<ProjectInfo[]> => {
        return this.migrateLegacyProjects().then(_ => this.openStore('readonly')).then(store => {
            return new Promise<ProjectInfo[]>((resolve, reject) => {
                const projects: ProjectInfo[] = []
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
    loadProject = (id: ProjectId): Promise<Project> =>
        this.migrateLegacyProjects()
            .then(_ => this.openStore('readonly'))
            .then(store => this.getProject(store, id))
            .then(p => p ? p : Promise.reject(`Not found`))
    createProject = (p: Project): Promise<Project> => {
        return this.openStore('readwrite').then(store => {
            return this.getProject(store, p.id).then(project => {
                if (project) {
                    return Promise.reject(`Project ${p.id} already exists in ${this.kind}`)
                } else {
                    const now = Date.now()
                    const prj = {...p, createdAt: now, updatedAt: now}
                    return reqToPromise(store.add(prj)).then(_ => prj)
                }
            })
        })
    }
    updateProject = (p: Project): Promise<Project> => {
        return this.openStore('readwrite').then(store => {
            return this.getProject(store, p.id).then(project => {
                if (project) {
                    const prj = {...p, updatedAt: Date.now()}
                    return reqToPromise(store.put(prj)).then(_ => prj)
                } else {
                    return Promise.reject(`Project ${p.id} doesn't exists in ${this.kind}`)
                }
            })
        })
    }
    dropProject = (p: ProjectInfo): Promise<void> => {
        return this.openStore('readwrite').then(store => reqToPromise(store.delete(p.id)))
    }

    private openStore(mode: IDBTransactionMode): Promise<IDBObjectStore> {
        return new Promise<IDBObjectStore>(resolve => resolve(this.db.transaction(IndexedDBStorage.dbProjects, mode).objectStore(IndexedDBStorage.dbProjects)))
    }

    private getProject(store: IDBObjectStore, id: ProjectId): Promise<Project | undefined> {
        return new Promise<Project>((resolve, reject) => {
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
                        .then(_ => legacyStorage.dropProject(p))
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
