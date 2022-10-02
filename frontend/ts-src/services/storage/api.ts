import {ProjectJson, ProjectStored, ProjectStoredWithId, ProjectId} from "../../types/project";

export type StorageKind = 'indexedDb' | 'localStorage' | 'inMemory' | 'manager'

export interface StorageApi {
    kind: StorageKind
    listProjects: () => Promise<ProjectStoredWithId[]>
    loadProject: (id: ProjectId) => Promise<ProjectStored>
    createProject: (id: ProjectId, p: ProjectJson) => Promise<ProjectJson>
    updateProject: (id: ProjectId, p: ProjectJson) => Promise<ProjectJson>
    deleteProject: (id: ProjectId) => Promise<void>
}
