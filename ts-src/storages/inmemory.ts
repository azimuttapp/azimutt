import {ProjectId, ProjectInfoNoStorage, ProjectNoStorage} from "../types/project";
import {projectToInfo, StorageApi, StorageKind} from "./api";

export class InMemoryStorage implements StorageApi {
    public kind: StorageKind = 'inMemory'

    constructor(private projects: { [id: string]: ProjectNoStorage } = {}) {
    }

    listProjects = (): Promise<ProjectInfoNoStorage[]> => Promise.resolve(Object.values(this.projects).map(projectToInfo))
    loadProject = (id: ProjectId): Promise<ProjectNoStorage> => this.projects[id] ? Promise.resolve(this.projects[id]) : Promise.reject(`Project ${id} not found`)
    createProject = (p: ProjectNoStorage): Promise<ProjectNoStorage> => {
        if(this.projects[p.id]) {
            return Promise.reject(`Project ${p.id} already exists in ${this.kind}`)
        } else {
            this.projects[p.id] = p
            return Promise.resolve(p)
        }
    }
    updateProject = (p: ProjectNoStorage): Promise<ProjectNoStorage> => {
        if(this.projects[p.id]) {
            this.projects[p.id] = p
            return Promise.resolve(p)
        } else {
            return Promise.reject(`Project ${p.id} doesn't exists in ${this.kind}`)
        }
    }
    dropProject = (id: ProjectId): Promise<void> => {
        delete this.projects[id]
        return Promise.resolve()
    }
}
