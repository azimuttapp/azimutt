import {ProjectJson, ProjectStored, ProjectStoredWithId, ProjectId} from "../../types/project";
import {AnyError} from "../../utils/error";

export type StorageKind = 'indexedDb' | 'localStorage' | 'inMemory' | 'manager'

export interface StorageApi {
    kind: StorageKind
    listProjects: () => Promise<[[ProjectId, AnyError][], ProjectStoredWithId[]]>
    loadProject: (id: ProjectId) => Promise<ProjectStored>
    createProject: (id: ProjectId, p: ProjectJson) => Promise<ProjectJson>
    updateProject: (id: ProjectId, p: ProjectJson) => Promise<ProjectJson>
    deleteProject: (id: ProjectId) => Promise<void>
}
