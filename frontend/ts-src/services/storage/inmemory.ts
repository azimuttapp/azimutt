import {LegacyProjectId, LegacyProjectJson, zodParse} from "@azimutt/models";
import {StorageApi, StorageKind} from "./api";
import {Logger} from "../logger";

export class InMemoryStorage implements StorageApi {
    public kind: StorageKind = 'inMemory'

    constructor(private logger: Logger, private projects: { [id: string]: LegacyProjectJson } = {}) {
    }

    loadProject = (id: LegacyProjectId): Promise<LegacyProjectJson> => {
        this.logger.debug(`inMemory.loadProject(${id})`)
        return this.projects[id] ? Promise.resolve(zodParse(LegacyProjectJson)(this.projects[id]).getOrThrow()) : Promise.reject(`Not found`)
    }
    createProject = (id: LegacyProjectId, p: LegacyProjectJson): Promise<LegacyProjectJson> => {
        this.logger.debug(`inMemory.createProject(${id})`, p)
        if(this.projects[id]) {
            return Promise.reject(`Project ${id} already exists in ${this.kind}`)
        } else {
            this.projects[id] = zodParse(LegacyProjectJson)(p).getOrThrow()
            return Promise.resolve(p)
        }
    }
    updateProject = (id: LegacyProjectId, p: LegacyProjectJson): Promise<LegacyProjectJson> => {
        this.logger.debug(`inMemory.updateProject(${id})`, p)
        if(this.projects[id]) {
            this.projects[id] = zodParse(LegacyProjectJson)(p).getOrThrow()
            return Promise.resolve(p)
        } else {
            return Promise.reject(`Project ${id} doesn't exists in ${this.kind}`)
        }
    }
    deleteProject = (id: LegacyProjectId): Promise<void> => {
        this.logger.debug(`inMemory.deleteProject(${id})`)
        delete this.projects[id]
        return Promise.resolve()
    }
}
