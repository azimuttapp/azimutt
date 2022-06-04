import {projectToInfo, StorageApi, StorageKind} from "./api";
import {Project, ProjectId, ProjectInfo, ProjectStorage} from "../types/project";
import {Supabase} from "../services/supabase";
import {IndexedDBStorage} from "./indexeddb";
import {LocalStorageStorage} from "./localstorage";
import {InMemoryStorage} from "./inmemory";
import {Logger} from "../services/logger";
import {Profile, UserId} from "../types/profile";
import {Email} from "../types/basics";

export class StorageManager implements StorageApi {
    public kind: StorageKind = 'manager'
    private browser: Promise<StorageApi>

    constructor(private cloud: Supabase, private enableCloud: boolean, private logger: Logger) {
        this.browser = IndexedDBStorage.init(logger).catch(() => LocalStorageStorage.init(logger)).catch(() => new InMemoryStorage())
    }

    listProjects = async (): Promise<ProjectInfo[]> => await Promise.all([
        this.browser.then(s => s.listProjects()),
        this.enableCloud ? this.cloud.listProjects() : Promise.resolve([])
    ]).then(projects => projects.flat())
    loadProject = (id: ProjectId): Promise<Project> => this.browser.then(s => s.loadProject(id)).catch(e => this.enableCloud ? this.cloud.loadProject(id) : Promise.reject(e))
    createProject = ({storage, ...p}: Project): Promise<Project> => {
        const now = Date.now()
        const prj = {...p, createdAt: now, updatedAt: now}
        return storage === 'cloud' && this.enableCloud ? this.cloud.createProject(prj) : this.browser.then(s => s.createProject(prj))
    }
    updateProject = ({storage, ...p}: Project): Promise<Project> => {
        const prj = {...p, updatedAt: Date.now()}
        return storage === 'cloud' && this.enableCloud ? this.cloud.updateProject(prj) : this.browser.then(s => s.updateProject(prj))
    }
    dropProject = (p: ProjectInfo): Promise<void> => p.storage === 'cloud' && this.enableCloud ? this.cloud.dropProject(p) : this.browser.then(s => s.dropProject(p))

    moveProjectTo = async (p: Project, storage: ProjectStorage): Promise<Project> => {
        if (p.storage === ProjectStorage.cloud) {
            if (storage === ProjectStorage.browser) {
                const project = {...p, storage}
                return await this.browser.then(s => s.createProject(project))
                    .then(_ => this.cloud.dropProject(projectToInfo(project)))
                    .then(_ => project)
            }
        } else if (p.storage === ProjectStorage.browser || p.storage === undefined) {
            if (storage === ProjectStorage.cloud) {
                const project = {...p, storage}
                return await this.cloud.createProject(project)
                    .then(_ => this.browser.then(s => s.dropProject(projectToInfo(project))))
                    .then(_ => project)
            }
        }
        return Promise.reject(`Unable to move project from ${p.storage} to ${storage}`)
    }

    getUser = (email: Email): Promise<Profile> => this.cloud.getUser(email)
    updateUser = (user: Profile): Promise<void> => this.cloud.updateUser(user)
    getOwners = (id: ProjectId): Promise<Profile[]> => this.cloud.getOwners(id)
    setOwners = (id: ProjectId, owners: UserId[]): Promise<Profile[]> => this.cloud.setOwners(id, owners)
}
