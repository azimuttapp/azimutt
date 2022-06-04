import {Project, ProjectId, ProjectInfo} from "../types/project";
import {projectToInfo, StorageApi, StorageKind} from "./api";
import {Logger} from "../services/logger";

export class LocalStorageStorage implements StorageApi {
    static init(logger: Logger): Promise<LocalStorageStorage> {
        return window.localStorage ?
            Promise.resolve(new LocalStorageStorage(window.localStorage, logger)) :
            Promise.reject('localStorage not available')
    }

    public kind: StorageKind = 'localStorage'
    private prefix = 'project-'

    constructor(private storage: Storage, private logger: Logger) {
    }

    listProjects = (): Promise<ProjectInfo[]> => {
        const projects = Object.keys(this.storage)
            .filter(key => key.startsWith(this.prefix))
            .flatMap(key => [this.getProject(key)].filter(p => p) as Project[])
            .map(projectToInfo)
        return Promise.resolve(projects)
    }
    loadProject = (id: ProjectId): Promise<Project> => Promise.resolve(this.getProject(this.prefix + id)).then(p => p ? p : Promise.reject(`Project ${id} not found`))
    createProject = (p: Project): Promise<Project> => {
        const key = this.prefix + p.id
        if (this.storage.getItem(key) === null) {
            return this.setProject(key, p)
        } else {
            return Promise.reject(`Project ${p.id} already exists in ${this.kind}`)
        }
    }
    updateProject = (p: Project): Promise<Project> => {
        const key = this.prefix + p.id
        if (this.storage.getItem(key) === null) {
            return Promise.reject(`Project ${p.id} doesn't exists in ${this.kind}`)
        } else {
            return this.setProject(key, p)
        }
    }
    dropProject = (p: ProjectInfo): Promise<void> => {
        this.storage.removeItem(this.prefix + p.id)
        return Promise.resolve()
    }

    private getProject = (key: string): Project | undefined => {
        const value = this.storage.getItem(key)
        if (value === null) {
            return undefined
        }
        try {
            return JSON.parse(value) as Project
        } catch (e) {
            this.logger.warn(`Invalid JSON in localStorage ${key}`)
            return undefined
        }
    }
    private setProject = (key: string, p: Project): Promise<Project> => {
        try {
            this.storage.setItem(key, JSON.stringify(p))
            return Promise.resolve(p)
        } catch (e) {
            return Promise.reject(e)
        }
    }
}
