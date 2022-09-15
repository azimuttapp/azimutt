import {StorageApi, StorageKind} from "./api";
import {
    Project,
    ProjectId,
    ProjectInfo,
    ProjectInfoNoStorage,
    ProjectNoStorage,
    ProjectStorage
} from "../types/project";
import {Supabase} from "../services/supabase";
import {IndexedDBStorage} from "./indexeddb";
import {LocalStorageStorage} from "./localstorage";
import {InMemoryStorage} from "./inmemory";
import {Logger} from "../services/logger";
import {Profile, UserId} from "../types/profile";
import {Email} from "../types/basics";

export class StorageManager {
    public kind: StorageKind = 'manager'
    private browser: Promise<StorageApi>

    constructor(private cloud: Supabase, private logger: Logger) {
        this.browser = IndexedDBStorage.init(logger).catch(() => LocalStorageStorage.init(logger)).catch(() => new InMemoryStorage())
    }

    listProjects = async (): Promise<ProjectInfo[]> => await Promise.all([
        this.browser.then(s => s.listProjects()).then(browserProjects),
        this.cloud.listProjects().then(cloudProjects)
    ]).then(projects => projects.flat())
    loadProject = (id: ProjectId): Promise<Project> =>
        this.browser.then(s => s.loadProject(id)).then(browserProject)
            .catch(_ => this.cloud.loadProject(id).then(cloudProject))
    createProject = ({storage, ...p}: Project): Promise<Project> => {
        const now = Date.now()
        const prj = {...p, createdAt: now, updatedAt: now}
        return storage === 'cloud' || storage === 'azimutt' ?
            this.cloud.createProject(prj).then(cloudProject) :
            this.browser.then(s => s.createProject(prj)).then(browserProject)
    }
    updateProject = ({storage, ...p}: Project): Promise<Project> => {
        const prj = {...p, updatedAt: Date.now()}
        return storage === 'cloud' || storage === 'azimutt' ?
            this.cloud.updateProject(prj).then(cloudProject) :
            this.browser.then(s => s.updateProject(prj)).then(browserProject)
    }
    dropProject = (p: ProjectInfo): Promise<void> =>
        p.storage === 'cloud' || p.storage === 'azimutt' ?
            this.cloud.deleteProject(p.id) :
            this.browser.then(s => s.deleteProject(p.id))

    moveProjectTo = async ({storage, ...p}: Project, toStorage: ProjectStorage): Promise<Project> => {
        const prj = {...p, updatedAt: Date.now()}
        if (storage === ProjectStorage.cloud && toStorage === ProjectStorage.browser) {
            return await this.browser.then(s => s.createProject(prj))
                .then(_ => this.cloud.deleteProject(prj.id))
                .then(_ => browserProject(prj))
        } else if ((storage === ProjectStorage.browser || storage === undefined) && toStorage === ProjectStorage.cloud) {
            return await this.cloud.createProject(prj)
                .then(_ => this.browser.then(s => s.deleteProject(prj.id)))
                .then(_ => cloudProject(prj))
        } else {
            return Promise.reject(`Unable to move project from ${storage} to ${toStorage}`)
        }
    }

    getUser = (email: Email): Promise<Profile> => this.cloud.getUser(email)
    updateUser = (user: Profile): Promise<void> => this.cloud.updateUser(user)
    getOwners = (id: ProjectId): Promise<Profile[]> => this.cloud.getOwners(id)
    setOwners = (id: ProjectId, owners: UserId[]): Promise<Profile[]> => this.cloud.setOwners(id, owners)
}

const cloudProjects = (projects: ProjectInfoNoStorage[]): ProjectInfo[] =>
    projects.map(p => ({...p, storage: ProjectStorage.cloud}))
const browserProjects = (projects: ProjectInfoNoStorage[]): ProjectInfo[] =>
    projects.map(p => ({...p, storage: ProjectStorage.browser}))

const cloudProject = (p: ProjectNoStorage): Project => ({...p, storage: ProjectStorage.cloud})
const browserProject = (p: ProjectNoStorage): Project => ({...p, storage: ProjectStorage.browser})
