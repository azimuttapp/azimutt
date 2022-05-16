import {StorageApi, StorageKind} from "./api";
import {Project, ProjectStorage} from "../types/project";
import {Supabase} from "../services/supabase";
import {IndexedDBStorage} from "./indexeddb";
import {LocalStorageStorage} from "./localstorage";
import {InMemoryStorage} from "./inmemory";
import {Logger} from "../services/logger";

export class StorageManager implements StorageApi {
    public kind: StorageKind = 'manager'
    private browser: Promise<StorageApi>

    constructor(private cloud: Supabase, private logger: Logger) {
        this.browser = IndexedDBStorage.init(logger).catch(() => LocalStorageStorage.init(logger)).catch(() => new InMemoryStorage())
    }

    loadProjects = async (): Promise<Project[]> => {
        return await Promise.all([
            this.browser.then(s => s.loadProjects()),
            this.cloud.loadProjects()
        ]).then((projects: Project[][]) => projects.flat())
    }
    saveProject = async (p: Project): Promise<void> => {
        return await p.storage === 'cloud' ? this.cloud.saveProject(p) : this.browser.then(s => s.saveProject(p))
    }
    dropProject = async (p: Project): Promise<void> => {
        return await p.storage === 'cloud' ? this.cloud.dropProject(p) : this.browser.then(s => s.dropProject(p))
    }

    moveProjectTo = async (p: Project, storage: ProjectStorage): Promise<Project> => {
        if (p.storage === 'cloud') {
            if (storage === 'browser') {
                const project = {...p, storage}
                return await this.browser.then(s => s.saveProject(project))
                    .then(_ => this.cloud.dropProject(project))
                    .then(_ => project)
            }
        } else if (p.storage === 'browser' || p.storage === undefined) {
            if (storage === 'cloud') {
                const project = {...p, storage}
                return await this.cloud.saveProject(project)
                    .then(_ => this.browser.then(s => s.dropProject(project)))
                    .then(_ => project)
            }
        }
        return Promise.reject(`Unable to move project from ${p.storage} to ${storage}`)
    }
}
