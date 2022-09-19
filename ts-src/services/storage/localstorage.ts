import {ProjectJson, ProjectStored, ProjectStoredWithId, ProjectId} from "../../types/project";
import {StorageApi, StorageKind} from "./api";
import {Logger} from "../logger";
import {formatError} from "../../utils/error";
import {successes} from "../../utils/promise";

export class LocalStorageStorage implements StorageApi {
    static init(logger: Logger): Promise<LocalStorageStorage> {
        return window.localStorage ?
            Promise.resolve(new LocalStorageStorage(logger)) :
            Promise.reject('localStorage not available')
    }

    public kind: StorageKind = 'localStorage'
    private prefix = 'project-'

    constructor(private logger: Logger) {
    }

    listProjects = (): Promise<ProjectStoredWithId[]> => {
        this.logger.debug(`localStorage.listProjects()`)
        const keys = Object.keys(window.localStorage).filter(key => key.startsWith(this.prefix))
        return successes(keys.map(k => this.getProject(k).then(p => [k.replace(this.prefix, ''), p])))
    }
    loadProject = (id: ProjectId): Promise<ProjectStored> => {
        this.logger.debug(`localStorage.loadProject(${id})`)
        return Promise.resolve(this.getProject(this.prefix + id)).then(p => p ? p : Promise.reject(`Project ${id} not found`))
    }
    createProject = (id: ProjectId, p: ProjectJson): Promise<ProjectJson> => {
        this.logger.debug(`localStorage.createProject(${id})`, p)
        const key = this.prefix + id
        if (window.localStorage.getItem(key) === null) {
            return this.setProject(key, p)
        } else {
            return Promise.reject(`Project ${id} already exists in ${this.kind}`)
        }
    }
    updateProject = (id: ProjectId, p: ProjectJson): Promise<ProjectJson> => {
        this.logger.debug(`localStorage.updateProject(${id})`, p)
        const key = this.prefix + id
        if (window.localStorage.getItem(key) === null) {
            return Promise.reject(`Project ${id} doesn't exists in ${this.kind}`)
        } else {
            return this.setProject(key, p)
        }
    }
    deleteProject = (id: ProjectId): Promise<void> => {
        this.logger.debug(`localStorage.deleteProject(${id})`)
        window.localStorage.removeItem(this.prefix + id)
        return Promise.resolve()
    }

    private getProject = (key: string): Promise<ProjectStored> => {
        const value = window.localStorage.getItem(key)
        if (value === null) {
            return Promise.reject(`Nothing in localStorage ${JSON.stringify(key)}`)
        }
        try {
            return Promise.resolve(JSON.parse(value) as ProjectStored)
        } catch (e) {
            return Promise.reject(`Invalid JSON in localStorage ${JSON.stringify(key)}: ${formatError(e)}`)
        }
    }
    private setProject = (key: string, p: ProjectJson): Promise<ProjectJson> => {
        try {
            window.localStorage.setItem(key, JSON.stringify(p))
            return Promise.resolve(p)
        } catch (e) {
            return Promise.reject(e)
        }
    }
}
