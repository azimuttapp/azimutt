import {Project} from "../types/project";
import {StorageApi, StorageKind} from "./api";

export class InMemoryStorage implements StorageApi {
    public kind: StorageKind = 'inMemory'

    constructor(private projects: { [id: string]: Project } = {}) {
    }

    loadProjects = (): Promise<Project[]> => Promise.resolve(Object.values(this.projects))
    saveProject = (p: Project): Promise<void> => {
        this.projects[p.id] = p
        return Promise.resolve()
    }
    dropProject = (p: Project): Promise<void> => {
        delete this.projects[p.id]
        return Promise.resolve()
    }
}
