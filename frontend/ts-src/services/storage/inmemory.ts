import {DatabaseUrl, LegacyProjectId, LegacyProjectJson, SourceId, zodParse} from "@azimutt/models";
import {StorageApi, StorageKind} from "./api";
import {Logger} from "../logger";

export class InMemoryStorage implements StorageApi {
    public kind: StorageKind = 'inMemory'

    constructor(private logger: Logger,
                private projects: { [id: LegacyProjectId]: LegacyProjectJson } = {},
                private connections: { [id: SourceId]: DatabaseUrl } = {}) {
    }

    getDbUrl = (id: SourceId): Promise<DatabaseUrl | undefined> => {
        this.logger.debug(`inMemory.getDbUrl(${id})`)
        return this.connections[id] ? zodParse(DatabaseUrl)(this.connections[id]).toPromise() : Promise.resolve(undefined)
    }

    setDbUrl = (id: SourceId, url: DatabaseUrl): Promise<void> => {
        this.logger.debug(`inMemory.setDbUrl(${id})`)
        return zodParse(DatabaseUrl)(url).toPromise().then(res => {
            this.connections[id] = res
        })
    }

    removeDbUrl = (id: SourceId): Promise<void> => {
        this.logger.debug(`inMemory.removeDbUrl(${id})`)
        delete this.connections[id]
        return Promise.resolve()
    }

    loadProject = (id: LegacyProjectId): Promise<LegacyProjectJson> => {
        this.logger.debug(`inMemory.loadProject(${id})`)
        return this.projects[id] ? zodParse(LegacyProjectJson)(this.projects[id]).toPromise() : Promise.reject(`Not found`)
    }
    createProject = (id: LegacyProjectId, p: LegacyProjectJson): Promise<LegacyProjectJson> => {
        this.logger.debug(`inMemory.createProject(${id})`, p)
        if(this.projects[id]) {
            return Promise.reject(`Project ${id} already exists in ${this.kind}`)
        } else {
            return zodParse(LegacyProjectJson)(p).toPromise().then(res => {
                this.projects[id] = res
                return res
            })
        }
    }
    updateProject = (id: LegacyProjectId, p: LegacyProjectJson): Promise<LegacyProjectJson> => {
        this.logger.debug(`inMemory.updateProject(${id})`, p)
        if(this.projects[id]) {
            return zodParse(LegacyProjectJson)(p).toPromise().then(res => {
                this.projects[id] = res
                return res
            })
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
