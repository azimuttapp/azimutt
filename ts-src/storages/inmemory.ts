import {Project, ProjectId, ProjectInfo} from "../types/project";
import {projectToInfo, StorageApi, StorageKind} from "./api";

export class InMemoryStorage implements StorageApi {
    public kind: StorageKind = 'inMemory'

    constructor(private projects: { [id: string]: Project } = {}) {
    }

    private loadProjects = (): Promise<Project[]> => Promise.resolve(Object.values(this.projects))
    listProjects = (): Promise<ProjectInfo[]> => this.loadProjects().then(projects => projects.map(projectToInfo))
    loadProject = (id: ProjectId): Promise<Project> => this.loadProjects().then(projects => projects.find(p => p.id === id) || Promise.reject(`Project ${id} not found`))
    createProject = (p: Project): Promise<void> => {
        this.projects[p.id] = p
        return Promise.resolve()
    }
    updateProject = (p: Project): Promise<void> => this.createProject(p)
    dropProject = (p: ProjectInfo): Promise<void> => {
        delete this.projects[p.id]
        return Promise.resolve()
    }
}
