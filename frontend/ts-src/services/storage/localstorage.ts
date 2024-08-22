import {errorToString} from "@azimutt/utils";
import {DatabaseUrl, LegacyProjectId, LegacyProjectJson, SourceId, zodParse, zodStringify} from "@azimutt/models";
import {StorageApi, StorageKind} from "./api";
import {Logger} from "../logger";
import * as Json from "../../utils/json";

export class LocalStorageStorage implements StorageApi {
    static init(logger: Logger): Promise<LocalStorageStorage> {
        return window.localStorage ?
            Promise.resolve(new LocalStorageStorage(logger)) :
            Promise.reject('localStorage not available')
    }

    public kind: StorageKind = 'localStorage'
    private prefixProject = 'project-'
    private prefixConnection = 'connection-'

    constructor(private logger: Logger) {
    }

    getDbUrl = async (id: SourceId): Promise<DatabaseUrl | undefined> => {
        this.logger.debug(`localStorage.getDbUrl(${id})`)
        const url = window.localStorage.getItem(this.connectionKey(id))
        return url || undefined
    }

    setDbUrl = async (id: SourceId, url: DatabaseUrl): Promise<void> => {
        this.logger.debug(`localStorage.setDbUrl(${id})`)
        window.localStorage.setItem(this.connectionKey(id), url)
    }

    removeDbUrl = async (id: SourceId): Promise<void> => {
        this.logger.debug(`localStorage.removeDbUrl(${id})`)
        window.localStorage.removeItem(this.connectionKey(id))
    }

    loadProject = (id: LegacyProjectId): Promise<LegacyProjectJson> => {
        this.logger.debug(`localStorage.loadProject(${id})`)
        return Promise.resolve(this.getProject(this.projectKey(id))).then(p => p ? p : Promise.reject(`Not found`))
    }
    createProject = (id: LegacyProjectId, p: LegacyProjectJson): Promise<LegacyProjectJson> => {
        this.logger.debug(`localStorage.createProject(${id})`, p)
        const key = this.projectKey(id)
        if (window.localStorage.getItem(key) === null) {
            return this.setProject(key, p)
        } else {
            return Promise.reject(`Project ${id} already exists in ${this.kind}`)
        }
    }
    updateProject = (id: LegacyProjectId, p: LegacyProjectJson): Promise<LegacyProjectJson> => {
        this.logger.debug(`localStorage.updateProject(${id})`, p)
        const key = this.projectKey(id)
        if (window.localStorage.getItem(key) === null) {
            return Promise.reject(`Project ${id} doesn't exists in ${this.kind}`)
        } else {
            return this.setProject(key, p)
        }
    }
    deleteProject = (id: LegacyProjectId): Promise<void> => {
        this.logger.debug(`localStorage.deleteProject(${id})`)
        window.localStorage.removeItem(this.projectKey(id))
        return Promise.resolve()
    }

    private projectKey = (id: LegacyProjectId): string => this.prefixProject + id
    private connectionKey = (id: SourceId): string => this.prefixConnection + id
    private getProject = (key: string): Promise<LegacyProjectJson> => {
        const value = window.localStorage.getItem(key)
        if (value === null) {
            return Promise.reject(`Nothing in localStorage ${JSON.stringify(key)}`)
        }
        try {
            return Promise.resolve(zodParse(LegacyProjectJson)(Json.parse(value)).getOrThrow())
        } catch (e) {
            return Promise.reject(`Invalid JSON in localStorage ${JSON.stringify(key)}: ${errorToString(e)}`)
        }
    }
    private setProject = (key: string, p: LegacyProjectJson): Promise<LegacyProjectJson> => {
        try {
            window.localStorage.setItem(key, zodStringify(LegacyProjectJson)(p))
            return Promise.resolve(p)
        } catch (e) {
            return Promise.reject(e)
        }
    }
}
