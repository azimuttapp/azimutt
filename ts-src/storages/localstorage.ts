import {Project} from "../types/project";
import {StorageApi, StorageKind} from "./api";

export class LocalStorageStorage implements StorageApi {
    static init(): Promise<LocalStorageStorage> {
        return window.localStorage ?
            Promise.resolve(new LocalStorageStorage(window.localStorage)) :
            Promise.reject('localStorage not available')
    }

    public kind: StorageKind = 'localStorage'
    private prefix = 'project-'

    constructor(private storage: Storage) {
    }

    loadProjects = (): Promise<Project[]> => {
        const projects = Object.keys(this.storage)
            .filter(key => key.startsWith(this.prefix))
            .flatMap(key => {
                const value = this.storage.getItem(key) || ''
                try {
                    return [JSON.parse(value)]
                } catch (e) {
                    console.warn(`Unable to parse ${key} project`)
                    return []
                }
            })
        return Promise.resolve(projects)
    }
    saveProject = (p: Project): Promise<void> => {
        const key = this.prefix + p.id
        const now = Date.now()
        p.updatedAt = now
        if (this.storage.getItem(key) === null) {
            p.createdAt = now
        }
        try {
            this.storage.setItem(key, JSON.stringify(p))
            return Promise.resolve()
        } catch (e) {
            return Promise.reject(e)
        }
    }
    dropProject = (p: Project): Promise<void> => {
        this.storage.removeItem(this.prefix + p.id)
        return Promise.resolve()
    }
}
