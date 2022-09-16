import {ProjectId, ProjectInfoNoStorage, ProjectNoStorage} from "../../types/project";
import {projectToInfo, StorageApi, StorageKind} from "./api";
import {Logger} from "../logger";

export class InMemoryStorage implements StorageApi {
    public kind: StorageKind = 'inMemory'

    constructor(private logger: Logger, private projects: { [id: string]: ProjectNoStorage } = {}) {
    }

    listProjects = (): Promise<ProjectInfoNoStorage[]> => {
        this.logger.debug(`inMemory.listProjects()`)
        return Promise.resolve(Object.entries(this.projects).map(([id, p]) => projectToInfo(id, p)))
    }
    loadProject = (id: ProjectId): Promise<ProjectNoStorage> => {
        this.logger.debug(`inMemory.loadProject(${id})`)
        return this.projects[id] ? Promise.resolve(this.projects[id]) : Promise.reject(`Project ${id} not found`)
    }
    createProject = (id: ProjectId, p: ProjectNoStorage): Promise<ProjectNoStorage> => {
        this.logger.debug(`inMemory.createProject(${id})`, p)
        if(this.projects[id]) {
            return Promise.reject(`Project ${id} already exists in ${this.kind}`)
        } else {
            this.projects[id] = p
            return Promise.resolve(p)
        }
    }
    updateProject = (id: ProjectId, p: ProjectNoStorage): Promise<ProjectNoStorage> => {
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
