import {ProjectId, ProjectInfoNoStorage, ProjectNoStorage} from "../../types/project";

export type StorageKind = 'indexedDb' | 'localStorage' | 'inMemory' | 'manager'

export interface StorageApi {
    kind: StorageKind
    listProjects: () => Promise<ProjectInfoNoStorage[]>
    loadProject: (id: ProjectId) => Promise<ProjectNoStorage>
    createProject: (id: ProjectId, p: ProjectNoStorage) => Promise<ProjectNoStorage>
    updateProject: (id: ProjectId, p: ProjectNoStorage) => Promise<ProjectNoStorage>
    deleteProject: (id: ProjectId) => Promise<void>
}
