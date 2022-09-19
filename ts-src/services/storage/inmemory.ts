import {ProjectJson, ProjectStored, ProjectStoredWithId, ProjectId} from "../../types/project";
import {StorageApi, StorageKind} from "./api";
import {Logger} from "../logger";

export class InMemoryStorage implements StorageApi {
    public kind: StorageKind = 'inMemory'

    constructor(private logger: Logger, private projects: { [id: string]: ProjectStored } = {}) {
    }

    listProjects = (): Promise<ProjectStoredWithId[]> => {
        this.logger.debug(`inMemory.listProjects()`)
        return Promise.resolve(Object.entries(this.projects))
    }
    loadProject = (id: ProjectId): Promise<ProjectStored> => {
        this.logger.debug(`inMemory.loadProject(${id})`)
        return this.projects[id] ? Promise.resolve(this.projects[id]) : Promise.reject(`Project ${id} not found`)
    }
    createProject = (id: ProjectId, p: ProjectJson): Promise<ProjectJson> => {
        this.logger.debug(`inMemory.createProject(${id})`, p)
        if(this.projects[id]) {
            return Promise.reject(`Project ${id} already exists in ${this.kind}`)
        } else {
            this.projects[id] = p
            return Promise.resolve(p)
        }
    }
    updateProject = (id: ProjectId, p: ProjectJson): Promise<ProjectJson> => {
        this.logger.debug(`inMemory.updateProject(${id})`, p)
        if(this.projects[id]) {
            this.projects[id] = p
            return Promise.resolve(p)
        } else {
            return Promise.reject(`Project ${id} doesn't exists in ${this.kind}`)
        }
    }
    deleteProject = (id: ProjectId): Promise<void> => {
        this.logger.debug(`inMemory.deleteProject(${id})`)
        delete this.projects[id]
        return Promise.resolve()
    }
}
