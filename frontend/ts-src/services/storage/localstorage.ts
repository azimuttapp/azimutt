import {errorToString} from "@azimutt/utils";
import {LegacyProjectId, LegacyProjectJson, zodStringify, zodValidate} from "@azimutt/database-model";
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
    private prefix = 'project-'

    constructor(private logger: Logger) {
    }

    loadProject = (id: LegacyProjectId): Promise<LegacyProjectJson> => {
        this.logger.debug(`localStorage.loadProject(${id})`)
        return Promise.resolve(this.getProject(this.idToKey(id))).then(p => p ? p : Promise.reject(`Not found`))
    }
    createProject = (id: LegacyProjectId, p: LegacyProjectJson): Promise<LegacyProjectJson> => {
        this.logger.debug(`localStorage.createProject(${id})`, p)
        const key = this.idToKey(id)
        if (window.localStorage.getItem(key) === null) {
            return this.setProject(key, p)
        } else {
            return Promise.reject(`Project ${id} already exists in ${this.kind}`)
        }
    }
    updateProject = (id: LegacyProjectId, p: LegacyProjectJson): Promise<LegacyProjectJson> => {
        this.logger.debug(`localStorage.updateProject(${id})`, p)
        const key = this.idToKey(id)
        if (window.localStorage.getItem(key) === null) {
            return Promise.reject(`Project ${id} doesn't exists in ${this.kind}`)
        } else {
            return this.setProject(key, p)
        }
    }
    deleteProject = (id: LegacyProjectId): Promise<void> => {
        this.logger.debug(`localStorage.deleteProject(${id})`)
        window.localStorage.removeItem(this.idToKey(id))
        return Promise.resolve()
    }

    private idToKey = (id: LegacyProjectId): string => this.prefix + id
    private getProject = (key: string): Promise<LegacyProjectJson> => {
        const value = window.localStorage.getItem(key)
        if (value === null) {
            return Promise.reject(`Nothing in localStorage ${JSON.stringify(key)}`)
        }
        try {
            return Promise.resolve(zodValidate(Json.parse(value), LegacyProjectJson, 'LegacyProjectJson'))
        } catch (e) {
            return Promise.reject(`Invalid JSON in localStorage ${JSON.stringify(key)}: ${errorToString(e)}`)
        }
    }
    private setProject = (key: string, p: LegacyProjectJson): Promise<LegacyProjectJson> => {
        try {
            window.localStorage.setItem(key, zodStringify(p, LegacyProjectJson, 'LegacyProjectJson'))
            return Promise.resolve(p)
        } catch (e) {
            return Promise.reject(e)
        }
    }
}
