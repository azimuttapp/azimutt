import {ProjectId, ProjectJson} from "../../types/project";
import {StorageApi, StorageKind} from "./api";
import {Logger} from "../logger";
import * as Zod from "../../utils/zod";

export class InMemoryStorage implements StorageApi {
    public kind: StorageKind = 'inMemory'

    constructor(private logger: Logger, private projects: { [id: string]: ProjectJson } = {}) {
    }

    loadProject = (id: ProjectId): Promise<ProjectJson> => {
        this.logger.debug(`inMemory.loadProject(${id})`)
        return this.projects[id] ? Promise.resolve(Zod.validate(this.projects[id], ProjectJson, 'ProjectJson')) : Promise.reject(`Not found`)
    }
    createProject = (id: ProjectId, p: ProjectJson): Promise<ProjectJson> => {
        this.logger.debug(`inMemory.createProject(${id})`, p)
        if(this.projects[id]) {
            return Promise.reject(`Project ${id} already exists in ${this.kind}`)
        } else {
            this.projects[id] = Zod.validate(p, ProjectJson, 'ProjectJson')
            return Promise.resolve(p)
        }
    }
    updateProject = (id: ProjectId, p: ProjectJson): Promise<ProjectJson> => {
        this.logger.debug(`inMemory.updateProject(${id})`, p)
        if(this.projects[id]) {
            this.projects[id] = Zod.validate(p, ProjectJson, 'ProjectJson')
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
