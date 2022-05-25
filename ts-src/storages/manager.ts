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

    constructor(private cloud: Supabase, private logger: Logger) {
        this.browser = IndexedDBStorage.init(logger).catch(() => LocalStorageStorage.init(logger)).catch(() => new InMemoryStorage())
    }

    listProjects = async (): Promise<ProjectInfo[]> => await Promise.all([
        this.browser.then(s => s.listProjects()),
        this.cloud.listProjects()
    ]).then(projects => projects.flat())
    loadProject = (id: ProjectId): Promise<Project> => this.browser.then(s => s.loadProject(id)).catch(_ => this.cloud.loadProject(id))
    createProject = (p: Project): Promise<Project> => p.storage === 'cloud' ? this.cloud.createProject(p) : this.browser.then(s => s.createProject(p))
    updateProject = (p: Project): Promise<Project> => p.storage === 'cloud' ? this.cloud.updateProject(p) : this.browser.then(s => s.updateProject(p))
    dropProject = (p: ProjectInfo): Promise<void> => p.storage === 'cloud' ? this.cloud.dropProject(p) : this.browser.then(s => s.dropProject(p))

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

    getUser = (email: Email): Promise<Profile | undefined> => this.cloud.getUser(email)
    updateUser = (user: Profile): Promise<Profile> => this.cloud.updateUser(user)
    getOwners = (id: ProjectId): Promise<Profile[]> => this.cloud.getOwners(id)
    setOwners = (id: ProjectId, owners: UserId[]): Promise<Profile[]> => this.cloud.setOwners(id, owners)
}
