import {ProjectId, ProjectJson} from "../../types/project";

export type StorageKind = 'indexedDb' | 'localStorage' | 'inMemory' | 'manager'

export interface StorageApi {
    kind: StorageKind
    loadProject: (id: ProjectId) => Promise<ProjectJson>
    createProject: (id: ProjectId, p: ProjectJson) => Promise<ProjectJson>
    updateProject: (id: ProjectId, p: ProjectJson) => Promise<ProjectJson>
    deleteProject: (id: ProjectId) => Promise<void>
}
